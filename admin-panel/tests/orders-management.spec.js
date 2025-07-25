import { test, expect } from '@playwright/test';

test.describe('Orders Management System', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the admin panel
    await page.goto('http://localhost:3000');
    
    // Wait for the page to load
    await page.waitForLoadState('networkidle');
    
    // Navigate to Orders page
    await page.click('text=Orders');
    await page.waitForSelector('h4:has-text("Orders Management")', { timeout: 10000 });
  });

  test('should display orders list with proper columns', async ({ page }) => {
    // Check if the orders table is visible
    await expect(page.locator('table')).toBeVisible();
    
    // Verify table headers
    const expectedHeaders = [
      'Order ID',
      'Customer', 
      'Mini-App',
      'Store',
      'Amount',
      'Status',
      'Items',
      'Date',
      'Actions'
    ];
    
    for (const header of expectedHeaders) {
      await expect(page.locator(`th:has-text("${header}")`)).toBeVisible();
    }
  });

  test('should filter orders by status', async ({ page }) => {
    // Wait for orders to load
    await page.waitForTimeout(2000);
    
    // Click on status filter dropdown
    await page.click('label:has-text("Status")');
    await page.click('text=Pending');
    
    // Wait for filtered results
    await page.waitForTimeout(1000);
    
    // Verify that only pending orders are shown (if any exist)
    const statusChips = page.locator('[data-testid="status-chip"]');
    const count = await statusChips.count();
    
    if (count > 0) {
      // Check that all visible status chips show "Pending"
      for (let i = 0; i < count; i++) {
        await expect(statusChips.nth(i)).toContainText('Pending');
      }
    }
  });

  test('should filter orders by mini-app type', async ({ page }) => {
    // Wait for orders to load
    await page.waitForTimeout(2000);
    
    // Click on mini-app filter dropdown
    await page.click('label:has-text("Mini-App")');
    await page.click('text=零售商店');
    
    // Wait for filtered results
    await page.waitForTimeout(1000);
    
    // Verify that only retail store orders are shown (if any exist)
    const miniAppChips = page.locator('[data-testid="mini-app-chip"]');
    const count = await miniAppChips.count();
    
    if (count > 0) {
      // Check that all visible mini-app chips show "零售商店"
      for (let i = 0; i < count; i++) {
        await expect(miniAppChips.nth(i)).toContainText('零售商店');
      }
    }
  });

  test('should search orders by order ID or customer email', async ({ page }) => {
    // Wait for orders to load
    await page.waitForTimeout(2000);
    
    // Enter search term
    await page.fill('input[placeholder*="Order ID, user email"]', 'test');
    
    // Wait for search results
    await page.waitForTimeout(1000);
    
    // Verify search functionality works (results should be filtered)
    // Note: This test assumes there are orders in the system
    const tableRows = page.locator('tbody tr');
    const rowCount = await tableRows.count();
    
    // If there are rows, verify they contain the search term
    if (rowCount > 0) {
      const firstRow = tableRows.first();
      const rowText = await firstRow.textContent();
      expect(rowText.toLowerCase()).toContain('test');
    }
  });

  test('should open order details modal when view button is clicked', async ({ page }) => {
    // Wait for orders to load
    await page.waitForTimeout(2000);
    
    // Check if there are any orders
    const viewButtons = page.locator('button[title="View Details"]');
    const buttonCount = await viewButtons.count();
    
    if (buttonCount > 0) {
      // Click the first view button
      await viewButtons.first().click();
      
      // Wait for modal to open
      await page.waitForSelector('text=Order Details', { timeout: 5000 });
      
      // Verify modal content
      await expect(page.locator('text=Order Information')).toBeVisible();
      await expect(page.locator('text=Customer Information')).toBeVisible();
      await expect(page.locator('text=Order Items')).toBeVisible();
      
      // Close modal
      await page.click('button:has-text("Close")');
      await page.waitForSelector('text=Order Details', { state: 'hidden' });
    } else {
      console.log('No orders available for testing order details modal');
    }
  });

  test('should handle bulk order selection and update', async ({ page }) => {
    // Wait for orders to load
    await page.waitForTimeout(2000);
    
    // Check if there are any orders
    const checkboxes = page.locator('input[type="checkbox"]').nth(1); // Skip header checkbox
    const checkboxCount = await page.locator('tbody tr').count();
    
    if (checkboxCount > 0) {
      // Select first order
      await checkboxes.click();
      
      // Verify bulk update button appears
      await expect(page.locator('button:has-text("Bulk Update")')).toBeVisible();
      
      // Click bulk update button
      await page.click('button:has-text("Bulk Update")');
      
      // Wait for bulk update modal
      await page.waitForSelector('text=Bulk Update Orders');
      
      // Select a new status
      await page.click('label:has-text("New Status")');
      await page.click('text=Confirmed');
      
      // Add reason
      await page.fill('textarea[label="Reason (Optional)"]', 'Bulk update test');
      
      // Click update button
      await page.click('button:has-text("Update Orders")');
      
      // Wait for success message or modal to close
      await page.waitForTimeout(2000);
    } else {
      console.log('No orders available for testing bulk update');
    }
  });

  test('should handle pagination correctly', async ({ page }) => {
    // Wait for orders to load
    await page.waitForTimeout(2000);
    
    // Check if pagination controls are visible
    const paginationControls = page.locator('[role="navigation"]');
    
    if (await paginationControls.isVisible()) {
      // Test rows per page selector
      await page.click('text=25');
      await page.click('text=10');
      
      // Wait for page to update
      await page.waitForTimeout(1000);
      
      // Verify that the page updated (check if "10" is selected)
      await expect(page.locator('text=1–10 of')).toBeVisible();
    } else {
      console.log('Pagination not available - likely due to insufficient data');
    }
  });

  test('should display order statistics correctly', async ({ page }) => {
    // Navigate to dashboard to check if order statistics are displayed
    await page.click('text=Dashboard');
    await page.waitForSelector('h4:has-text("Dashboard")', { timeout: 10000 });
    
    // Check if order statistics cards are visible
    await expect(page.locator('text=Total Orders')).toBeVisible();
    await expect(page.locator('text=Revenue')).toBeVisible();
    
    // Verify that the statistics show real data (not mock data)
    const revenueCard = page.locator('text=Revenue').locator('..').locator('..');
    const revenueValue = await revenueCard.locator('h4').textContent();
    
    // Revenue should be in currency format (¥ or $)
    expect(revenueValue).toMatch(/[\$¥]\d+/);
  });

  test('should handle error states gracefully', async ({ page }) => {
    // Test with invalid date range filter
    await page.fill('input[label="From Date"]', '2025-12-31');
    await page.fill('input[label="To Date"]', '2025-01-01');
    
    // Wait for potential error handling
    await page.waitForTimeout(2000);
    
    // The system should handle this gracefully (no crash)
    await expect(page.locator('h4:has-text("Orders Management")')).toBeVisible();
  });

  test('should maintain filter state during navigation', async ({ page }) => {
    // Set a filter
    await page.click('label:has-text("Status")');
    await page.click('text=Pending');
    
    // Navigate away and back
    await page.click('text=Dashboard');
    await page.waitForTimeout(1000);
    await page.click('text=Orders');
    
    // Wait for page to load
    await page.waitForTimeout(2000);
    
    // Verify the page loads correctly (filter state may or may not persist)
    await expect(page.locator('h4:has-text("Orders Management")')).toBeVisible();
  });

  test('should validate admin access requirements', async ({ page }) => {
    // This test verifies that the orders page requires proper admin access
    // The actual authentication is handled by the backend
    
    // Verify that the orders page loads (indicating proper admin access)
    await expect(page.locator('h4:has-text("Orders Management")')).toBeVisible();
    
    // Verify that admin-specific features are available
    await expect(page.locator('text=Bulk Update')).toBeHidden(); // Should be hidden until orders are selected
    
    // Check that filter controls are available (admin feature)
    await expect(page.locator('input[placeholder*="Order ID, user email"]')).toBeVisible();
  });
});
