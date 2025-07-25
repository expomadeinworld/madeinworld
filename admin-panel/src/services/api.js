import axios from 'axios';

// Create axios instance with base configuration
const api = axios.create({
  baseURL: 'http://localhost:8080/api/v1',
  timeout: 10000, // 10 seconds timeout
  headers: {
    'Content-Type': 'application/json',
    'X-Admin-Request': 'true', // Mark all requests as admin requests
  },
});

// Request interceptor for logging and auth (if needed in future)
api.interceptors.request.use(
  (config) => {
    console.log(`Making ${config.method?.toUpperCase()} request to: ${config.url}`);
    return config;
  },
  (error) => {
    console.error('Request error:', error);
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
    const response = await axios.get('http://localhost:8083/api/admin/users', {
      params,
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800'
      }
    });
    return response.data;
  },

  // Get single user by ID
  getUser: async (userId) => {
    const response = await axios.get(`http://localhost:8083/api/admin/users/${userId}`, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800'
      }
    });
    return response.data;
  },

  // Update user
  updateUser: async (userId, userData) => {
    const response = await axios.put(`http://localhost:8083/api/admin/users/${userId}`, userData, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800'
      }
    });
    return response.data;
  },

  // Delete user
  deleteUser: async (userId) => {
    const response = await axios.delete(`http://localhost:8083/api/admin/users/${userId}`, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Update user status
  updateUserStatus: async (userId, statusData) => {
    const response = await axios.post(`http://localhost:8083/api/admin/users/${userId}/status`, statusData, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Get user analytics
  getUserAnalytics: async () => {
    const response = await axios.get('http://localhost:8083/api/admin/users/analytics', {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Bulk update users
  bulkUpdateUsers: async (bulkData) => {
    const response = await axios.post('http://localhost:8083/api/admin/users/bulk-update', bulkData, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
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
    const response = await axios.get('http://localhost:8082/api/admin/orders', {
      params,
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Get single order by ID
  getOrder: async (orderId) => {
    const response = await axios.get(`http://localhost:8082/api/admin/orders/${orderId}`, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Update order status
  updateOrderStatus: async (orderId, status, reason = '') => {
    const response = await axios.put(`http://localhost:8082/api/admin/orders/${orderId}/status`, {
      status,
      reason
    }, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Delete/cancel order
  deleteOrder: async (orderId) => {
    const response = await axios.delete(`http://localhost:8082/api/admin/orders/${orderId}`, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Bulk update orders
  bulkUpdateOrders: async (orderIds, status, reason = '') => {
    const response = await axios.post('http://localhost:8082/api/admin/orders/bulk-update', {
      order_ids: orderIds,
      status,
      reason
    }, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Get order statistics
  getStatistics: async (dateFrom = '', dateTo = '') => {
    const params = {};
    if (dateFrom) params.date_from = dateFrom;
    if (dateTo) params.date_to = dateTo;

    const response = await axios.get('http://localhost:8082/api/admin/orders/statistics', {
      params,
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },
};

// Cart service methods
export const cartService = {
  // Get all carts with pagination and filtering
  getCarts: async (params = {}) => {
    const response = await axios.get('http://localhost:8082/api/admin/carts', {
      params,
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Get single cart by ID
  getCart: async (cartId) => {
    const response = await axios.get(`http://localhost:8082/api/admin/carts/${cartId}`, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Update cart item quantity
  updateCartItem: async (cartId, productId, quantity) => {
    const response = await axios.put(`http://localhost:8082/api/admin/carts/${cartId}/items`, {
      product_id: productId,
      quantity: quantity
    }, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Delete cart
  deleteCart: async (cartId) => {
    const response = await axios.delete(`http://localhost:8082/api/admin/carts/${cartId}`, {
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },

  // Get cart statistics
  getStatistics: async (dateFrom = '', dateTo = '') => {
    const params = {};
    if (dateFrom) params.date_from = dateFrom;
    if (dateTo) params.date_to = dateTo;

    const response = await axios.get('http://localhost:8082/api/admin/carts/statistics', {
      params,
      headers: {
        'X-Admin-Request': 'true',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQG1hZGVpbndvcmxkLmNvbSIsImV4cCI6MTc1MzU0NjgxNCwiaWF0IjoxNzUzNDYwNDE0LCJ1c2VyX2lkIjoiZDI4M2NhOTMtY2IzNy00Y2FmLWFkNGEtMjhiMzA4ZDM5YWMxIn0._eMrn6U7_5KoGbXdRAFhHhU3-L3hfbvuZirA2AQz800' // TODO: Replace with real auth
      }
    });
    return response.data;
  },
};

// Export the axios instance as default for custom requests
export default api;
