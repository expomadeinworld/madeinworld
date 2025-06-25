import React from 'react';
import { HashRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import theme from './theme/theme';
import Layout from './components/Layout';

// Import page components
import DashboardPage from './pages/DashboardPage';
import ProductListPage from './pages/ProductListPage';

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Layout>
          <Routes>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/products" element={<ProductListPage />} />
            {/* Future routes */}
            <Route path="/stores" element={<div>Stores Page (Coming Soon)</div>} />
            <Route path="/users" element={<div>Users Page (Coming Soon)</div>} />
            <Route path="/analytics" element={<div>Analytics Page (Coming Soon)</div>} />
          </Routes>
        </Layout>
      </Router>
    </ThemeProvider>
  );
}

export default App;
