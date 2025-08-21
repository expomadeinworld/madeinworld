import axios from 'axios';

// Single base URL via Cloudflare Worker
const API_BASE = process.env.REACT_APP_API_BASE_URL || 'https://device-api.expomadeinworld.com';
export const AUTH_BASE = `${API_BASE}/api/auth`;
export const ADMIN_BASE = `${API_BASE}/api/admin`;
export const CATALOG_BASE = `${API_BASE}/api/v1`;

// Create axios instance with base configuration (Catalog API v1)
const api = axios.create({
  baseURL: CATALOG_BASE,
  timeout: 10000, // 10 seconds timeout
  headers: {
    'Content-Type': 'application/json'
  },
});


// Request interceptor for logging and auth
api.interceptors.request.use(
  (config) => {
    console.log(`Making ${config.method?.toUpperCase()} request to: ${config.url}`);

    // Add authorization header if token exists
    const savedToken = localStorage.getItem('admin_token');
    if (savedToken) {
      try {
        const tokenData = JSON.parse(savedToken);
        if (tokenData.token) {
          config.headers.Authorization = `Bearer ${tokenData.token}`;
        }
      } catch (error) {
        console.error('Error parsing stored token:', error);
      }
    }

    return config;
  },
  (error) => {
    console.error('Request error:', error);
    return Promise.reject(error);
  }
);

// Helper function to get auth headers
const getAuthHeaders = () => {
  const savedToken = localStorage.getItem('admin_token');
  if (savedToken) {
    try {
      const tokenData = JSON.parse(savedToken);
      if (tokenData.token) {
        return {
          'X-Admin-Request': 'true',
          'Authorization': `Bearer ${tokenData.token}`
        };
      }
    } catch (error) {
      console.error('Error parsing stored token:', error);
    }
  }
  return {
    'X-Admin-Request': 'true'
  };
};

// Response interceptor for handling auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Clear invalid token
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');

      // Redirect to login if not already there
      if (window.location.hash !== '#/login') {
        window.location.hash = '#/login';
      }
    }
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    console.log(`Response from ${response.config.url}:`, response.status);
    return response;
  },
  (error) => {
    console.error('Response error:', error);
    
    // Handle common error scenarios
    if (error.response) {
      // Server responded with error status
      const { status, data } = error.response;
      console.error(`API Error ${status}:`, data);
      
      switch (status) {
        case 400:
          throw new Error(data.error || 'Bad request');
        case 404:
          throw new Error('Resource not found');
        case 409:
          throw new Error(data.error || 'Conflict - resource already exists');
        case 500:
          throw new Error('Internal server error');
        default:
          throw new Error(data.error || `Server error: ${status}`);
      }
    } else if (error.request) {
      // Network error
      console.error('Network error:', error.request);
      throw new Error('Network error - please check your connection');
    } else {
      // Other error
      console.error('Error:', error.message);
      throw new Error(error.message);
    }
  }
);

// User service methods
export const userService = {
  // Get all users with pagination and filtering
  getUsers: async (params = {}) => {
    const response = await axios.get(`${ADMIN_BASE}/users`, {
      params,
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Get single user by ID
  getUser: async (userId) => {
    const response = await axios.get(`${ADMIN_BASE}/users/${userId}`, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Create new user
  createUser: async (userData) => {
    const response = await axios.post(`${ADMIN_BASE}/users`, userData, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Update user
  updateUser: async (userId, userData) => {
    const response = await axios.put(`${ADMIN_BASE}/users/${userId}`, userData, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Delete user
  deleteUser: async (userId) => {
    const response = await axios.delete(`${ADMIN_BASE}/users/${userId}`, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Update user status
  updateUserStatus: async (userId, statusData) => {
    const response = await axios.post(`${ADMIN_BASE}/users/${userId}/status`, statusData, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Get user analytics
  getUserAnalytics: async () => {
    const response = await axios.get(`${ADMIN_BASE}/users/analytics`, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Bulk update users
  bulkUpdateUsers: async (bulkData) => {
    const response = await axios.post(`${ADMIN_BASE}/users/bulk-update`, bulkData, {
      headers: getAuthHeaders()
    });
    return response.data;
  },
};

// API service methods
export const productService = {
  // Get all products
  getProducts: async (params = {}) => {
    const response = await api.get('/products', { params });
    return response.data;
  },

  // Get single product by ID
  getProduct: async (id) => {
    const response = await api.get(`/products/${id}`);
    return response.data;
  },

  // Create new product
  createProduct: async (productData) => {
    const response = await api.post('/products', productData);
    return response.data;
  },

  // Update existing product
  updateProduct: async (productId, productData) => {
    const response = await api.put(`/products/${productId}`, productData);
    return response.data;
  },

  // Delete product (soft delete by default)
  deleteProduct: async (productId, hardDelete = false) => {
    const params = hardDelete ? { hard: 'true' } : {};
    const response = await api.delete(`/products/${productId}`, { params });
    return response.data;
  },

  // Upload product image
  uploadProductImage: async (productId, imageFile) => {
    const formData = new FormData();
    formData.append('productImage', imageFile);

    const response = await api.post(`/products/${productId}/image`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  },
};

export const categoryService = {
  // Get all categories
  getCategories: async (params = {}) => {
    const response = await api.get('/categories', { params });
    return response.data;
  },

  // Get categories by mini-app type and store (for dynamic filtering)
  getCategoriesByMiniApp: async (miniAppType, storeId = null) => {
    const params = {
      mini_app_type: miniAppType,
      include_subcategories: true
    };
    if (storeId) {
      params.store_id = storeId;
    }
    const response = await api.get('/categories', { params });
    return response.data;
  },

  // Get subcategories for a specific category
  getSubcategories: async (categoryId) => {
    const response = await api.get(`/categories/${categoryId}/subcategories`);
    return response.data;
  },

  // Get single category by ID
  getCategory: async (id) => {
    const response = await api.get(`/categories/${id}`);
    return response.data;
  },

  // Create new category
  createCategory: async (categoryData) => {
    const response = await api.post('/categories', categoryData);
    return response.data;
  },
};

export const storeService = {
  // Get all stores
  getStores: async (params = {}) => {
    const response = await api.get('/stores', { params });
    return response.data;
  },

  // Get stores by mini-app type (for dynamic filtering)
  getStoresByMiniApp: async (miniAppType) => {
    const params = { mini_app_type: miniAppType };
    const response = await api.get('/stores', { params });
    return response.data;
  },

  // Get stores by specific store type
  getStoresByType: async (storeType) => {
    const params = { type: storeType };
    const response = await api.get('/stores', { params });
    return response.data;
  },
};

export const healthService = {
  // Check service health
  checkHealth: async () => {
    const response = await api.get('/health');
    return response.data;
  },
};

// Order service methods
export const orderService = {
  // Get all orders with pagination and filtering
  getOrders: async (params = {}) => {
    const response = await axios.get(`${ADMIN_BASE}/orders`, {
      params,
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Get single order by ID
  getOrder: async (orderId) => {
    const response = await axios.get(`${ADMIN_BASE}/orders/${orderId}`, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Update order status
  updateOrderStatus: async (orderId, status, reason = '') => {
    const response = await axios.put(`${ADMIN_BASE}/orders/${orderId}/status`, {
      status,
      reason
    }, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Delete/cancel order
  deleteOrder: async (orderId) => {
    const response = await axios.delete(`${ADMIN_BASE}/orders/${orderId}`, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Bulk update orders
  bulkUpdateOrders: async (orderIds, status, reason = '') => {
    const response = await axios.post(`${ADMIN_BASE}/orders/bulk-update`, {
      order_ids: orderIds,
      status,
      reason
    }, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Get order statistics
  getStatistics: async (dateFrom = '', dateTo = '') => {
    const params = {};
    if (dateFrom) params.date_from = dateFrom;
    if (dateTo) params.date_to = dateTo;

    const response = await axios.get(`${ADMIN_BASE}/orders/statistics`, {
      params,
      headers: getAuthHeaders()
    });
    return response.data;
  },
};

// Cart service methods
export const cartService = {
  // Get all carts with pagination and filtering
  getCarts: async (params = {}) => {
    const response = await axios.get(`${ADMIN_BASE}/carts`, {
      params,
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Get single cart by ID
  getCart: async (cartId) => {
    const response = await axios.get(`${ADMIN_BASE}/carts/${cartId}`, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Update cart item quantity
  updateCartItem: async (cartId, productId, quantity) => {
    const response = await axios.put(`${ADMIN_BASE}/carts/${cartId}/items`, {
      product_id: productId,
      quantity: quantity
    }, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Delete cart
  deleteCart: async (cartId) => {
    const response = await axios.delete(`${ADMIN_BASE}/carts/${cartId}`, {
      headers: getAuthHeaders()
    });
    return response.data;
  },

  // Get cart statistics
  getStatistics: async (dateFrom = '', dateTo = '') => {
    const params = {};
    if (dateFrom) params.date_from = dateFrom;
    if (dateTo) params.date_to = dateTo;

    const response = await axios.get(`${ADMIN_BASE}/carts/statistics`, {
      params,
      headers: getAuthHeaders()
    });
    return response.data;
  },
};

// Export the axios instance as default for custom requests
export default api;
