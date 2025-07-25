import React from 'react';
import { HashRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import theme from './theme/theme';
import Layout from './components/Layout';

// Import page components
import DashboardPage from './pages/DashboardPage';
import ProductListPage from './pages/ProductListPage';
import CategoryListPage from './pages/CategoryListPage';
import StoreListPage from './pages/StoreListPage';
import UserListPage from './pages/UserListPage';
import OrderListPage from './pages/OrderListPage';
import CartListPage from './pages/CartListPage';
import { ToastProvider } from './contexts/ToastContext';

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <ToastProvider>
        <Router>
          <Layout>
            <Routes>
              <Route path="/" element={<DashboardPage />} />
              <Route path="/products" element={<ProductListPage />} />
              <Route path="/categories" element={<CategoryListPage />} />
              <Route path="/stores" element={<StoreListPage />} />
              <Route path="/users" element={<UserListPage />} />
              <Route path="/orders" element={<OrderListPage />} />
              <Route path="/carts" element={<CartListPage />} />
              <Route path="/analytics" element={<div>Analytics Page (Coming Soon)</div>} />
            </Routes>
          </Layout>
        </Router>
      </ToastProvider>
    </ThemeProvider>
  );
}

export default App;
