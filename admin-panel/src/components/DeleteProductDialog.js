import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Alert,
  CircularProgress,
  Avatar,
} from '@mui/material';
import {
  Warning as WarningIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { productService } from '../services/api';
import { useToast } from '../contexts/ToastContext';

const DeleteProductDialog = ({ open, onClose, product, onProductDeleted }) => {
  const { showSuccess, showError } = useToast();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleDelete = async () => {
    try {
      setLoading(true);
      setError(null);

      // Call the real API to delete the product (soft delete)
      await productService.deleteProduct(product.id);
      console.log('Product deleted successfully:', product.id);

      showSuccess(`Product "${product.title}" deleted successfully!`);

      // Notify parent component and close dialog
      onProductDeleted();
      onClose();
      
    } catch (err) {
      console.error('Error deleting product:', err);
      setError(err.message || 'Failed to delete product');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      setError(null);
      onClose();
    }
  };

  if (!product) return null;

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: { borderRadius: '12px' }
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <WarningIcon color="error" sx={{ fontSize: 32 }} />
          <Typography variant="h5" sx={{ fontWeight: 600 }}>
            Delete Product
          </Typography>
        </Box>
      </DialogTitle>

      <DialogContent sx={{ pt: 6, pb: 2 }}>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Box sx={{ textAlign: 'center', py: 2 }}>
          {/* Product Preview */}
          <Avatar
            src={product.image_urls?.[0]}
            alt={product.title}
            sx={{ 
              width: 80, 
              height: 80, 
              mx: 'auto', 
              mb: 2,
              border: '2px solid #e0e0e0'
            }}
            variant="rounded"
          />

          <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
            {product.title}
          </Typography>
          
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            SKU: {product.sku}
          </Typography>

          <Alert severity="warning" sx={{ textAlign: 'left', mb: 2 }}>
            <Typography variant="body2">
              <strong>Warning:</strong> This action cannot be undone. Deleting this product will:
            </Typography>
            <Box component="ul" sx={{ mt: 1, mb: 0, pl: 2 }}>
              <li>Remove the product from all store listings</li>
              <li>Delete all associated images and data</li>
              <li>Remove it from customer carts and wishlists</li>
              <li>Affect any ongoing orders or inventory tracking</li>
            </Box>
          </Alert>

          <Typography variant="body1" sx={{ fontWeight: 500 }}>
            Are you sure you want to delete this product?
          </Typography>
        </Box>
      </DialogContent>

      <DialogActions sx={{ p: 3, pt: 1 }}>
        <Button 
          onClick={handleClose} 
          disabled={loading}
          variant="outlined"
        >
          Cancel
        </Button>
        
        <Button
          onClick={handleDelete}
          disabled={loading}
          variant="contained"
          color="error"
          startIcon={loading ? <CircularProgress size={20} /> : <DeleteIcon />}
          sx={{
            '&:hover': {
              backgroundColor: '#d32f2f',
            }
          }}
        >
          {loading ? 'Deleting...' : 'Delete Product'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default DeleteProductDialog;
