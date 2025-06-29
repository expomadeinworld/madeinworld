import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Alert,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Avatar,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Visibility as ViewIcon,
  Delete as DeleteIcon,
  Store as StoreIcon,
} from '@mui/icons-material';
import { productService } from '../services/api';
import ProductForm from '../components/ProductForm';
import ProductDetailsModal from '../components/ProductDetailsModal';
import DeleteProductDialog from '../components/DeleteProductDialog';
import ProductStatusToggle from '../components/ProductStatusToggle';

const ProductListPage = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Modal states
  const [addModalOpen, setAddModalOpen] = useState(false);
  const [detailsModalOpen, setDetailsModalOpen] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await productService.getProducts();
      // Ensure we always have an array, even if API returns null
      setProducts(Array.isArray(data) ? data : []);
    } catch (err) {
      console.error('Error fetching products:', err);
      setError(err.message || 'Failed to load products');
      // Set empty array on error to prevent null reference errors
      setProducts([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, []);

  const handleAddProduct = () => {
    setAddModalOpen(true);
  };

  const handleCloseModal = () => {
    setAddModalOpen(false);
  };

  const handleProductCreated = () => {
    // Refresh the product list after successful creation
    fetchProducts();
    setAddModalOpen(false);
  };

  // Handler functions for CRUD operations
  const handleViewDetails = (product) => {
    setSelectedProduct(product);
    setDetailsModalOpen(true);
  };

  const handleEditProduct = (product) => {
    setSelectedProduct(product);
    setEditModalOpen(true);
  };

  const handleDeleteProduct = (product) => {
    setSelectedProduct(product);
    setDeleteDialogOpen(true);
  };

  const handleProductUpdated = () => {
    // Refresh the product list after successful update
    fetchProducts();
    setEditModalOpen(false);
    setSelectedProduct(null);
  };

  const handleProductDeleted = () => {
    // Refresh the product list after successful deletion
    fetchProducts();
    setDeleteDialogOpen(false);
    setSelectedProduct(null);
  };

  const handleCloseModals = () => {
    setDetailsModalOpen(false);
    setEditModalOpen(false);
    setDeleteDialogOpen(false);
    setSelectedProduct(null);
  };

  const handleStatusChanged = (productId, newStatus) => {
    // Update the product status in the local state
    setProducts(prevProducts =>
      prevProducts.map(product =>
        product.id === productId
          ? { ...product, is_active: newStatus }
          : product
      )
    );
  };

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
        size="small"
        color={isUnmanned ? 'primary' : 'default'}
        variant={isUnmanned ? 'filled' : 'outlined'}
        sx={{
          fontWeight: 500,
          fontSize: '12px',
        }}
      />
    );
  };

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

  return (
    <Box>
      {/* Page Header */}
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          mb: 4,
        }}
      >
        <Box>
          <Typography variant="h4" gutterBottom sx={{ fontWeight: 700 }}>
            Products
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Manage your product catalog and inventory
          </Typography>
        </Box>
        
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleAddProduct}
          sx={{
            borderRadius: '8px',
            textTransform: 'none',
            fontWeight: 600,
            px: 3,
            py: 1.5,
          }}
        >
          Add Product
        </Button>
      </Box>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Products Table */}
      <Card>
        <CardContent sx={{ p: 0 }}>
          <TableContainer component={Paper} elevation={0}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell sx={{ fontWeight: 600 }}>Product</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>SKU</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Categories</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Store Type</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Price</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Stock</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Status</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {!products || products.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                      <Box sx={{ textAlign: 'center' }}>
                        <StoreIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
                        <Typography variant="h6" color="text.secondary" gutterBottom>
                          No products found
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          Get started by adding your first product
                        </Typography>
                      </Box>
                    </TableCell>
                  </TableRow>
                ) : (
                  (products || []).map((product) => (
                    <TableRow
                      key={product.id}
                      hover
                      sx={{
                        opacity: product.is_active ? 1 : 0.6,
                        backgroundColor: product.is_active ? 'inherit' : 'action.hover'
                      }}
                    >
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                          <Avatar
                            src={product.image_urls?.[0]}
                            alt={product.title}
                            sx={{
                              width: 48,
                              height: 48,
                              filter: product.is_active ? 'none' : 'grayscale(50%)'
                            }}
                            variant="rounded"
                          >
                            <StoreIcon />
                          </Avatar>
                          <Box>
                            <Typography
                              variant="body1"
                              sx={{
                                fontWeight: 500,
                                textDecoration: product.is_active ? 'none' : 'line-through',
                                color: product.is_active ? 'text.primary' : 'text.secondary'
                              }}
                            >
                              {product.title}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                              {product.description_short}
                            </Typography>
                          </Box>
                        </Box>
                      </TableCell>
                      
                      <TableCell>
                        <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                          {product.sku}
                        </Typography>
                      </TableCell>

                      {/* Categories Column */}
                      <TableCell>
                        <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                          {product.category_ids && product.category_ids.length > 0 ? (
                            product.category_ids.map((categoryId) => (
                              <Chip
                                key={categoryId}
                                label={`Cat ${categoryId}`}
                                size="small"
                                variant="outlined"
                                sx={{ fontSize: '0.75rem', height: 20 }}
                              />
                            ))
                          ) : (
                            <Typography variant="body2" color="text.secondary">
                              No categories
                            </Typography>
                          )}
                        </Box>
                      </TableCell>

                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          {getStoreTypeChip(product.store_type)}
                          {/* Featured indicator for Unmanned stores only */}
                          {product.store_type?.toLowerCase() === 'unmanned' && product.is_featured && (
                            <Chip
                              label="热门推荐"
                              size="small"
                              color="secondary"
                              variant="filled"
                              sx={{ fontSize: '0.75rem', height: 20 }}
                            />
                          )}
                        </Box>
                      </TableCell>
                      
                      <TableCell>
                        <Box>
                          <Typography variant="body1" sx={{ fontWeight: 600 }}>
                            {formatPrice(product.main_price)}
                          </Typography>
                          {product.strikethrough_price && (
                            <Typography
                              variant="body2"
                              sx={{
                                textDecoration: 'line-through',
                                color: 'text.secondary',
                              }}
                            >
                              {formatPrice(product.strikethrough_price)}
                            </Typography>
                          )}
                        </Box>
                      </TableCell>
                      
                      <TableCell>
                        {(product.store_type === '无人门店' || product.store_type === '无人仓店' || product.store_type?.toLowerCase() === 'unmanned') ? (
                          <Typography variant="body2">
                            {product.stock_left || 0} units
                          </Typography>
                        ) : (
                          <Typography variant="body2" color="text.secondary">
                            N/A
                          </Typography>
                        )}
                      </TableCell>
                      
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <ProductStatusToggle
                            product={product}
                            onStatusChanged={handleStatusChanged}
                          />
                          <Chip
                            label={product.is_active ? 'Active' : 'Inactive'}
                            size="small"
                            color={product.is_active ? 'success' : 'default'}
                            variant="filled"
                          />
                        </Box>
                      </TableCell>
                      
                      <TableCell>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                          <Tooltip title="View Details">
                            <IconButton
                              size="small"
                              onClick={() => handleViewDetails(product)}
                              sx={{ color: 'primary.main' }}
                            >
                              <ViewIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Edit Product">
                            <IconButton
                              size="small"
                              onClick={() => handleEditProduct(product)}
                              sx={{ color: 'warning.main' }}
                            >
                              <EditIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Delete Product">
                            <IconButton
                              size="small"
                              onClick={() => handleDeleteProduct(product)}
                              sx={{ color: 'error.main' }}
                            >
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Add Product Modal */}
      <ProductForm
        open={addModalOpen}
        onClose={handleCloseModal}
        onProductCreated={handleProductCreated}
      />

      {/* Product Details Modal */}
      <ProductDetailsModal
        open={detailsModalOpen}
        onClose={handleCloseModals}
        product={selectedProduct}
      />

      {/* Edit Product Modal */}
      <ProductForm
        open={editModalOpen}
        onClose={handleCloseModals}
        product={selectedProduct}
        onProductUpdated={handleProductUpdated}
      />

      {/* Delete Product Dialog */}
      <DeleteProductDialog
        open={deleteDialogOpen}
        onClose={handleCloseModals}
        product={selectedProduct}
        onProductDeleted={handleProductDeleted}
      />
    </Box>
  );
};

export default ProductListPage;
