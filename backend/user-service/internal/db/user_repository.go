package db

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"strings"
	"time"

	"user-service/internal/models"

	"golang.org/x/crypto/bcrypt"
)

// UserRepository handles user database operations
type UserRepository struct {
	db *Database
}

// NewUserRepository creates a new user repository
func NewUserRepository(db *Database) *UserRepository {
	return &UserRepository{db: db}
}

// hashPassword hashes a password using bcrypt
func hashPassword(password string) (string, error) {
	hashedBytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hashedBytes), nil
}

// GetUsers retrieves users with pagination, search, and filtering
func (r *UserRepository) GetUsers(ctx context.Context, params models.UserSearchParams) (*models.UserListResponse, error) {
	// Build the base query
	baseQuery := `
		SELECT u.id, u.username, u.email, u.password_hash,
		       u.first_name, u.last_name, u.role, u.status, u.last_login,
		       u.created_at, u.updated_at,
		       COALESCE(order_stats.order_count, 0) as order_count,
		       COALESCE(order_stats.total_spent, 0) as total_spent
		FROM users u
		LEFT JOIN (
			SELECT user_id,
			       COUNT(*) as order_count,
			       SUM(total_amount) as total_spent
			FROM orders
			GROUP BY user_id
		) order_stats ON u.id = order_stats.user_id
	`

	// Build WHERE clause
	var whereConditions []string
	var args []interface{}
	argIndex := 1

	if params.Search != "" {
		whereConditions = append(whereConditions, fmt.Sprintf(`
			(LOWER(u.username) LIKE LOWER($%d) OR
			 LOWER(u.email) LIKE LOWER($%d) OR
			 LOWER(u.first_name) LIKE LOWER($%d) OR
			 LOWER(u.last_name) LIKE LOWER($%d))`, argIndex, argIndex, argIndex, argIndex))
		args = append(args, "%"+params.Search+"%")
		argIndex++
	}

	if params.Role != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("u.role = $%d", argIndex))
		args = append(args, string(*params.Role))
		argIndex++
	}

	// Add WHERE clause if we have conditions
	if len(whereConditions) > 0 {
		baseQuery += " WHERE " + strings.Join(whereConditions, " AND ")
	}

	// Add ORDER BY clause
	orderBy := "u.created_at"
	if params.Sort != "" {
		switch params.Sort {
		case "full_name":
			orderBy = "u.full_name"
		case "email":
			orderBy = "u.email"
		case "last_login":
			orderBy = "u.last_login"
		case "role":
			orderBy = "u.role"
		case "order_count":
			orderBy = "order_count"
		case "total_spent":
			orderBy = "total_spent"
		}
	}

	order := "DESC"
	if params.Order == "asc" {
		order = "ASC"
	}

	baseQuery += fmt.Sprintf(" ORDER BY %s %s", orderBy, order)

	// Add pagination
	baseQuery += fmt.Sprintf(" LIMIT $%d OFFSET $%d", argIndex, argIndex+1)
	args = append(args, params.Limit, (params.Page-1)*params.Limit)

	log.Printf("Executing query: %s with args: %v", baseQuery, args)

	// Execute the query
	rows, err := r.db.DB.QueryContext(ctx, baseQuery, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query users: %w", err)
	}
	defer rows.Close()

	var users []models.User
	for rows.Next() {
		var user models.User
		var lastLogin sql.NullTime
		err := rows.Scan(
			&user.ID,
			&user.Username,
			&user.Email,
			&user.PasswordHash,
			&user.FirstName,
			&user.LastName,
			&user.Role,
			&user.Status,
			&lastLogin,
			&user.CreatedAt,
			&user.UpdatedAt,
			&user.OrderCount,
			&user.TotalSpent,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}

		// Set computed fields
		user.FullName = user.Username // Use username as display name
		if user.FirstName != nil && user.LastName != nil {
			user.FullName = *user.FirstName + " " + *user.LastName
		}

		// Set last login if valid
		if lastLogin.Valid {
			user.LastLogin = &lastLogin.Time
		}

		users = append(users, user)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over users: %w", err)
	}

	// Get total count
	total, err := r.getUserCount(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("failed to get user count: %w", err)
	}

	totalPages := (total + params.Limit - 1) / params.Limit

	return &models.UserListResponse{
		Users:      users,
		Total:      total,
		Page:       params.Page,
		Limit:      params.Limit,
		TotalPages: totalPages,
	}, nil
}

// getUserCount gets the total count of users matching the search criteria
func (r *UserRepository) getUserCount(ctx context.Context, params models.UserSearchParams) (int, error) {
	query := "SELECT COUNT(*) FROM users u"

	var whereConditions []string
	var args []interface{}
	argIndex := 1

	if params.Search != "" {
		whereConditions = append(whereConditions, fmt.Sprintf(`
			(LOWER(u.username) LIKE LOWER($%d) OR
			 LOWER(u.email) LIKE LOWER($%d) OR
			 LOWER(u.first_name) LIKE LOWER($%d) OR
			 LOWER(u.last_name) LIKE LOWER($%d) OR
			 u.phone LIKE $%d)`, argIndex, argIndex, argIndex, argIndex, argIndex))
		args = append(args, "%"+params.Search+"%")
		argIndex++
	}

	if params.Role != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("u.role = $%d", argIndex))
		args = append(args, string(*params.Role))
		argIndex++
	}

	if len(whereConditions) > 0 {
		query += " WHERE " + strings.Join(whereConditions, " AND ")
	}

	var count int
	err := r.db.DB.QueryRowContext(ctx, query, args...).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count users: %w", err)
	}

	return count, nil
}

// GetUserByID retrieves a user by ID with order statistics
func (r *UserRepository) GetUserByID(ctx context.Context, userID string) (*models.User, error) {
	query := `
		SELECT u.id, u.username, u.email, u.password_hash,
		       u.first_name, u.last_name, u.role, u.status, u.last_login,
		       u.created_at, u.updated_at,
		       COALESCE(order_stats.order_count, 0) as order_count,
		       COALESCE(order_stats.total_spent, 0) as total_spent
		FROM users u
		LEFT JOIN (
			SELECT user_id,
			       COUNT(*) as order_count,
			       SUM(total_amount) as total_spent
			FROM orders
			WHERE user_id = $1
			GROUP BY user_id
		) order_stats ON u.id = order_stats.user_id
		WHERE u.id = $1
	`

	var user models.User
	var lastLogin sql.NullTime
	err := r.db.DB.QueryRowContext(ctx, query, userID).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.PasswordHash,
		&user.FirstName,
		&user.LastName,
		&user.Role,
		&user.Status,
		&lastLogin,
		&user.CreatedAt,
		&user.UpdatedAt,
		&user.OrderCount,
		&user.TotalSpent,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	// Set computed fields
	user.FullName = user.Username
	if user.FirstName != nil && user.LastName != nil {
		user.FullName = *user.FirstName + " " + *user.LastName
	}

	// Set last login if valid
	if lastLogin.Valid {
		user.LastLogin = &lastLogin.Time
	}

	return &user, nil
}

// CreateUser creates a new user in the database
func (r *UserRepository) CreateUser(ctx context.Context, req models.UserCreateRequest) (*models.User, error) {
	// Hash the password
	hashedPassword, err := hashPassword(req.Password)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Insert user into database
	var user models.User
	query := `
		INSERT INTO users (username, email, password_hash, first_name, last_name, role, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, username, email, password_hash, first_name, last_name, role, status, created_at, updated_at
	`

	err = r.db.DB.QueryRowContext(ctx, query,
		req.Username, req.Email, hashedPassword,
		req.FirstName, req.LastName, req.Role, req.Status).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.PasswordHash,
		&user.FirstName,
		&user.LastName,
		&user.Role,
		&user.Status,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Set computed fields
	user.FullName = user.Username
	if user.FirstName != nil && user.LastName != nil {
		user.FullName = *user.FirstName + " " + *user.LastName
	}

	return &user, nil
}

// UpdateUser updates user information
func (r *UserRepository) UpdateUser(ctx context.Context, userID string, updates models.UserUpdateRequest) error {
	var setParts []string
	var args []interface{}
	argIndex := 1

	if updates.FullName != nil {
		// Split full name into first_name and last_name
		names := strings.Fields(*updates.FullName)
		if len(names) >= 1 {
			setParts = append(setParts, fmt.Sprintf("first_name = $%d", argIndex))
			args = append(args, names[0])
			argIndex++
		}
		if len(names) >= 2 {
			lastName := strings.Join(names[1:], " ")
			setParts = append(setParts, fmt.Sprintf("last_name = $%d", argIndex))
			args = append(args, lastName)
			argIndex++
		}
	}

	if updates.Email != nil {
		setParts = append(setParts, fmt.Sprintf("email = $%d", argIndex))
		args = append(args, *updates.Email)
		argIndex++
	}

	if updates.Role != nil {
		setParts = append(setParts, fmt.Sprintf("role = $%d", argIndex))
		args = append(args, string(*updates.Role))
		argIndex++
	}

	if updates.Status != nil {
		setParts = append(setParts, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, string(*updates.Status))
		argIndex++
	}

	if len(setParts) == 0 {
		return fmt.Errorf("no fields to update")
	}

	// Always update the updated_at timestamp
	setParts = append(setParts, fmt.Sprintf("updated_at = $%d", argIndex))
	args = append(args, time.Now())
	argIndex++

	// Add user ID for WHERE clause
	args = append(args, userID)

	query := fmt.Sprintf("UPDATE users SET %s WHERE id = $%d", strings.Join(setParts, ", "), argIndex)

	result, err := r.db.DB.ExecContext(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found")
	}

	return nil
}

// DeleteUser performs a hard delete of a user from the database
func (r *UserRepository) DeleteUser(ctx context.Context, userID string) error {
	// Start a transaction to ensure data consistency
	tx, err := r.db.DB.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Delete related data first (orders, carts, etc.)
	// Delete user's carts
	_, err = tx.ExecContext(ctx, "DELETE FROM carts WHERE user_id = $1", userID)
	if err != nil {
		return fmt.Errorf("failed to delete user carts: %w", err)
	}

	// Delete user's orders
	_, err = tx.ExecContext(ctx, "DELETE FROM orders WHERE user_id = $1", userID)
	if err != nil {
		return fmt.Errorf("failed to delete user orders: %w", err)
	}

	// Finally delete the user
	result, err := tx.ExecContext(ctx, "DELETE FROM users WHERE id = $1", userID)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found")
	}

	// Commit the transaction
	if err = tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// GetUserAnalytics retrieves user analytics data
func (r *UserRepository) GetUserAnalytics(ctx context.Context) (*models.UserAnalytics, error) {
	analytics := &models.UserAnalytics{
		UsersByRole:   make(map[models.UserRole]int),
		UsersByStatus: make(map[models.UserStatus]int),
	}

	// Get total users
	err := r.db.DB.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&analytics.TotalUsers)
	if err != nil {
		return nil, fmt.Errorf("failed to get total users: %w", err)
	}

	// Get users by role
	roleQuery := "SELECT role, COUNT(*) FROM users GROUP BY role"
	rows, err := r.db.DB.QueryContext(ctx, roleQuery)
	if err != nil {
		return nil, fmt.Errorf("failed to get users by role: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var role string
		var count int
		if err := rows.Scan(&role, &count); err != nil {
			return nil, fmt.Errorf("failed to scan role data: %w", err)
		}
		analytics.UsersByRole[models.UserRole(role)] = count
	}

	// Get new users today
	todayQuery := "SELECT COUNT(*) FROM users WHERE DATE(created_at) = CURRENT_DATE"
	err = r.db.DB.QueryRowContext(ctx, todayQuery).Scan(&analytics.NewUsersToday)
	if err != nil {
		return nil, fmt.Errorf("failed to get new users today: %w", err)
	}

	// Get new users this week
	weekQuery := "SELECT COUNT(*) FROM users WHERE created_at >= DATE_TRUNC('week', CURRENT_DATE)"
	err = r.db.DB.QueryRowContext(ctx, weekQuery).Scan(&analytics.NewUsersThisWeek)
	if err != nil {
		return nil, fmt.Errorf("failed to get new users this week: %w", err)
	}

	// Get active users (logged in within last 30 days)
	activeQuery := "SELECT COUNT(*) FROM users WHERE last_login >= $1"
	thirtyDaysAgo := time.Now().AddDate(0, 0, -30)
	err = r.db.DB.QueryRowContext(ctx, activeQuery, thirtyDaysAgo).Scan(&analytics.ActiveUsers)
	if err != nil {
		return nil, fmt.Errorf("failed to get active users: %w", err)
	}

	// Get registration trend (last 7 days)
	trendQuery := `
		SELECT DATE(created_at) as date, COUNT(*) as count
		FROM users
		WHERE created_at >= $1
		GROUP BY DATE(created_at)
		ORDER BY date DESC
	`
	sevenDaysAgo := time.Now().AddDate(0, 0, -7)
	trendRows, err := r.db.DB.QueryContext(ctx, trendQuery, sevenDaysAgo)
	if err != nil {
		return nil, fmt.Errorf("failed to get registration trend: %w", err)
	}
	defer trendRows.Close()

	for trendRows.Next() {
		var item models.RegistrationTrendItem
		var date time.Time
		if err := trendRows.Scan(&date, &item.Count); err != nil {
			return nil, fmt.Errorf("failed to scan trend data: %w", err)
		}
		item.Date = date.Format("2006-01-02")
		analytics.RegistrationTrend = append(analytics.RegistrationTrend, item)
	}

	// Calculate status distribution based on last login
	analytics.UsersByStatus[models.StatusActive] = analytics.ActiveUsers
	analytics.UsersByStatus[models.StatusDeactivated] = analytics.TotalUsers - analytics.ActiveUsers

	return analytics, nil
}

// GetUserOrderStats retrieves order statistics for a specific user
func (r *UserRepository) GetUserOrderStats(ctx context.Context, userID string) (*models.UserOrderStats, error) {
	query := `
		SELECT
			COUNT(*) as total_orders,
			COALESCE(SUM(total_amount), 0) as total_spent,
			COALESCE(AVG(total_amount), 0) as average_order,
			MAX(created_at) as last_order_date
		FROM orders
		WHERE user_id = $1
	`

	var stats models.UserOrderStats
	err := r.db.DB.QueryRowContext(ctx, query, userID).Scan(
		&stats.TotalOrders,
		&stats.TotalSpent,
		&stats.AverageOrder,
		&stats.LastOrderDate,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get user order stats: %w", err)
	}

	return &stats, nil
}

// BulkUpdateUsers performs bulk operations on multiple users
func (r *UserRepository) BulkUpdateUsers(ctx context.Context, userIDs []string, operation string, updates map[string]interface{}) error {
	if len(userIDs) == 0 {
		return fmt.Errorf("no user IDs provided")
	}

	// Create placeholders for user IDs
	placeholders := make([]string, len(userIDs))
	args := make([]interface{}, len(userIDs))
	for i, id := range userIDs {
		placeholders[i] = fmt.Sprintf("$%d", i+1)
		args[i] = id
	}

	var query string
	var additionalArgs []interface{}

	switch operation {
	case "role_update":
		if role, ok := updates["role"]; ok {
			query = fmt.Sprintf("UPDATE users SET role = $%d, updated_at = $%d WHERE user_id IN (%s)",
				len(args)+1, len(args)+2, strings.Join(placeholders, ","))
			additionalArgs = append(additionalArgs, role, time.Now())
		} else {
			return fmt.Errorf("role not provided for role_update operation")
		}
	default:
		return fmt.Errorf("unsupported bulk operation: %s", operation)
	}

	args = append(args, additionalArgs...)

	result, err := r.db.DB.ExecContext(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("failed to perform bulk update: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	log.Printf("Bulk operation %s affected %d rows", operation, rowsAffected)
	return nil
}
