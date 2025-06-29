import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Grid,
  Card,
  CardMedia,
  Chip,
  Divider,
  IconButton,
} from '@mui/material';
import {
  Close as CloseIcon,
  Inventory as InventoryIcon,
  AttachMoney as PriceIcon,
  Category as CategoryIcon,
} from '@mui/icons-material';

const ProductDetailsModal = ({ open, onClose, product }) => {
  if (!product) return null;

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(price);
  };

  const getStoreTypeChip = (storeType) => {
    const isUnmanned = storeType?.toLowerCase() === 'unmanned';
    return (
      <Chip
        label={storeType}
        size="medium"
        color={isUnmanned ? 'primary' : 'default'}
        variant={isUnmanned ? 'filled' : 'outlined'}
        sx={{ fontWeight: 500 }}
      />
    );
  };

  const getStatusChip = (isActive) => (
    <Chip
      label={isActive ? 'Active' : 'Inactive'}
      size="medium"
      color={isActive ? 'success' : 'default'}
      variant="filled"
      sx={{ fontWeight: 500 }}
    />
  );



  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { borderRadius: '12px' }
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h5" sx={{ fontWeight: 600 }}>
            Product Details
          </Typography>
          <IconButton onClick={onClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>

      <DialogContent sx={{ pt: 6, pb: 2 }}>
        <Grid container spacing={3}>
          {/* Product Image */}
          <Grid item xs={12} md={4}>
            <Card sx={{ borderRadius: '12px' }}>
              <CardMedia
                component="img"
                height="300"
                image={product.image_urls?.[0] || '/placeholder-product.png'}
                alt={product.title}
                sx={{
                  objectFit: 'cover',
                  backgroundColor: '#f5f5f5',
                }}
              />
            </Card>
          </Grid>

          {/* Product Information */}
          <Grid item xs={12} md={8}>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {/* Title and SKU */}
              <Box>
                <Typography variant="h4" gutterBottom sx={{ fontWeight: 700 }}>
                  {product.title}
                </Typography>
                <Typography variant="body1" color="text.secondary" sx={{ fontFamily: 'monospace' }}>
                  SKU: {product.sku}
                </Typography>
              </Box>

              {/* Status Chips */}
              <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                {getStoreTypeChip(product.store_type)}
                {getStatusChip(product.is_active)}
                {/* Only show featured chip for unmanned stores */}
                {(product.store_type === '无人门店' || product.store_type === '无人仓店' || product.store_type?.toLowerCase() === 'unmanned') && product.is_featured && (
                  <Chip
                    label="热门推荐 Featured"
                    size="medium"
                    color="secondary"
                    variant="filled"
                    sx={{ fontWeight: 500 }}
                  />
                )}
              </Box>

              {/* Pricing */}
              <Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                  <PriceIcon color="primary" />
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    Pricing
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                  <Typography variant="h5" sx={{ fontWeight: 700, color: 'primary.main' }}>
                    {formatPrice(product.main_price)}
                  </Typography>
                  {product.strikethrough_price && (
                    <Typography
                      variant="h6"
                      sx={{
                        textDecoration: 'line-through',
                        color: 'text.secondary',
                      }}
                    >
                      {formatPrice(product.strikethrough_price)}
                    </Typography>
                  )}
                </Box>
              </Box>

              {/* Stock Information */}
              {(product.store_type === '无人门店' || product.store_type === '无人仓店' || product.store_type?.toLowerCase() === 'unmanned') && (
                <Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <InventoryIcon color="primary" />
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                      Stock Information
                    </Typography>
                  </Box>
                  <Typography variant="body1">
                    {product.stock_left || 0} units available
                  </Typography>
                </Box>
              )}

              {/* Categories */}
              <Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                  <CategoryIcon color="primary" />
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    Categories
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                  {product.category_ids && product.category_ids.length > 0 ? (
                    product.category_ids.map((categoryId) => (
                      <Chip
                        key={categoryId}
                        label={`Category ${categoryId}`}
                        size="medium"
                        variant="outlined"
                        color="primary"
                      />
                    ))
                  ) : (
                    <Typography variant="body2" color="text.secondary">
                      No categories assigned
                    </Typography>
                  )}
                </Box>
              </Box>

              {/* Featured Status - Only for Unmanned Stores */}
              {product.store_type?.toLowerCase() === 'unmanned' && (
                <Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                      Featured Status
                    </Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    {product.is_featured ? (
                      <Chip
                        label="热门推荐 - Featured Product"
                        size="medium"
                        color="secondary"
                        variant="filled"
                        sx={{ fontWeight: 500 }}
                      />
                    ) : (
                      <Chip
                        label="Not Featured"
                        size="medium"
                        variant="outlined"
                        sx={{ fontWeight: 500 }}
                      />
                    )}
                  </Box>
                  <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                    {product.is_featured
                      ? 'This product appears in the main app\'s featured section'
                      : 'This product is not featured in the main app'
                    }
                  </Typography>
                </Box>
              )}
            </Box>
          </Grid>

          {/* Descriptions */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
            
            {/* Short Description */}
            {product.description_short && (
              <Box sx={{ mb: 3 }}>
                <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
                  Short Description
                </Typography>
                <Typography variant="body1" color="text.secondary">
                  {product.description_short}
                </Typography>
              </Box>
            )}

            {/* Long Description */}
            {product.description_long && (
              <Box>
                <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
                  Detailed Description
                </Typography>
                <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.6 }}>
                  {product.description_long}
                </Typography>
              </Box>
            )}
          </Grid>

          {/* Metadata */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
            <Box sx={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Created At
                </Typography>
                <Typography variant="body2">
                  {product.created_at ? new Date(product.created_at).toLocaleDateString() : 'N/A'}
                </Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Last Updated
                </Typography>
                <Typography variant="body2">
                  {product.updated_at ? new Date(product.updated_at).toLocaleDateString() : 'N/A'}
                </Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Manufacturer ID
                </Typography>
                <Typography variant="body2">
                  {product.manufacturer_id || 'N/A'}
                </Typography>
              </Box>
            </Box>
          </Grid>
        </Grid>
      </DialogContent>

      <DialogActions sx={{ p: 3, pt: 1 }}>
        <Button onClick={onClose} variant="outlined">
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ProductDetailsModal;
