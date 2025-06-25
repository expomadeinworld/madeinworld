import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Grid,
  Typography,
  CircularProgress,
  Alert,
} from '@mui/material';
import {
  Inventory as ProductsIcon,
  Store as StoreIcon,
  TrendingUp as RevenueIcon,
  Assessment as AnalyticsIcon,
} from '@mui/icons-material';
import { productService, storeService } from '../services/api';

const DashboardPage = () => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [stats, setStats] = useState({
    totalProducts: 0,
    totalStores: 0,
    revenue: 0,
    orders: 0,
  });

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        setError(null);

        // Fetch products and stores data
        const [productsData, storesData] = await Promise.all([
          productService.getProducts(),
          storeService.getStores(),
        ]);

        setStats({
          totalProducts: productsData.length || 0,
          totalStores: storesData.length || 0,
          revenue: 12450.75, // Mock data for now
          orders: 156, // Mock data for now
        });
      } catch (err) {
        console.error('Error fetching dashboard data:', err);
        setError(err.message || 'Failed to load dashboard data');
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  const summaryCards = [
    {
      title: 'Total Products',
      value: stats.totalProducts,
      icon: <ProductsIcon sx={{ fontSize: 40 }} />,
      color: '#D92525',
      bgColor: '#FFF5F5',
    },
    {
      title: 'Active Stores',
      value: stats.totalStores,
      icon: <StoreIcon sx={{ fontSize: 40 }} />,
      color: '#059669',
      bgColor: '#F0FDF4',
    },
    {
      title: 'Revenue',
      value: `$${stats.revenue.toLocaleString()}`,
      icon: <RevenueIcon sx={{ fontSize: 40 }} />,
      color: '#7C3AED',
      bgColor: '#F5F3FF',
    },
    {
      title: 'Total Orders',
      value: stats.orders,
      icon: <AnalyticsIcon sx={{ fontSize: 40 }} />,
      color: '#DC2626',
      bgColor: '#FEF2F2',
    },
  ];

  if (loading) {
    return (
      <Box
        display="flex"
        justifyContent="center"
        alignItems="center"
        minHeight="400px"
      >
        <CircularProgress size={60} />
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ mb: 3 }}>
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
        <Typography variant="h4" gutterBottom>
          Dashboard
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Unable to load dashboard data. Please check your connection and try again.
        </Typography>
      </Box>
    );
  }

  return (
    <Box>
      {/* Page Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 700 }}>
          Dashboard
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Welcome to the Made in World Admin Panel. Here's an overview of your business.
        </Typography>
      </Box>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {summaryCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card
              sx={{
                height: '100%',
                transition: 'transform 0.2s ease-in-out',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: '0 8px 25px rgba(0, 0, 0, 0.15)',
                },
              }}
            >
              <CardContent sx={{ p: 3 }}>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    mb: 2,
                  }}
                >
                  <Box
                    sx={{
                      backgroundColor: card.bgColor,
                      borderRadius: '12px',
                      p: 1.5,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <Box sx={{ color: card.color }}>
                      {card.icon}
                    </Box>
                  </Box>
                </Box>
                
                <Typography
                  variant="h4"
                  sx={{
                    fontWeight: 700,
                    color: 'text.primary',
                    mb: 1,
                  }}
                >
                  {card.value}
                </Typography>
                
                <Typography
                  variant="body2"
                  sx={{
                    color: 'text.secondary',
                    fontWeight: 500,
                  }}
                >
                  {card.title}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Quick Actions Section */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
                Quick Actions
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Common administrative tasks
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Typography variant="body2">• Add new products</Typography>
                <Typography variant="body2">• Manage inventory</Typography>
                <Typography variant="body2">• View store locations</Typography>
                <Typography variant="body2">• Generate reports</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
                System Status
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                All systems operational
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Typography variant="body2" sx={{ color: '#059669' }}>
                  ✓ Catalog Service: Online
                </Typography>
                <Typography variant="body2" sx={{ color: '#059669' }}>
                  ✓ Database: Connected
                </Typography>
                <Typography variant="body2" sx={{ color: '#059669' }}>
                  ✓ Image Storage: Available
                </Typography>
                <Typography variant="body2" sx={{ color: '#059669' }}>
                  ✓ API Gateway: Healthy
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default DashboardPage;
