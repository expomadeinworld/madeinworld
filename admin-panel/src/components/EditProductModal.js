import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  Stepper,
  Step,
  StepLabel,
  Card,
  CardContent,
  Avatar,
  IconButton,
  FormControlLabel,
  Switch,
} from '@mui/material';
import {
  CloudUpload as UploadIcon,
  CheckCircle as SuccessIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import { productService } from '../services/api';
import CategorySelector from './CategorySelector';

const steps = ['Edit Product Details', 'Update Image (Optional)'];

const EditProductModal = ({ open, onClose, product, onProductUpdated }) => {
  const [activeStep, setActiveStep] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  
  // Form data initialized with existing product data
  const [formData, setFormData] = useState({
    title: '',
    sku: '',
    description_short: '',
    description_long: '',
    store_type: 'Unmanned',
    main_price: '',
    strikethrough_price: '',
    is_featured: false,
    is_active: true,
    category_ids: [],
  });
  
  // Step 2 data
  const [selectedImage, setSelectedImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);

  // Initialize form data when product changes
  useEffect(() => {
    if (product) {
      setFormData({
        title: product.title || '',
        sku: product.sku || '',
        description_short: product.description_short || '',
        description_long: product.description_long || '',
        store_type: product.store_type || 'Unmanned',
        main_price: product.main_price?.toString() || '',
        strikethrough_price: product.strikethrough_price?.toString() || '',
        is_featured: product.is_featured || false,
        is_active: product.is_active !== undefined ? product.is_active : true,
        category_ids: product.category_ids || [],
      });
      setImagePreview(product.image_urls?.[0] || null);
    }
  }, [product]);

  const handleInputChange = (field) => (event) => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    setFormData({
      ...formData,
      [field]: value,
    });
  };

  const handleCategoriesChange = (categoryIds) => {
    setFormData({
      ...formData,
      category_ids: categoryIds,
    });
  };

  const handleImageSelect = (event) => {
    const file = event.target.files[0];
    if (file) {
      setSelectedImage(file);
      
      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        setImagePreview(e.target.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleStep1Submit = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Validate required fields
      if (!formData.title || !formData.sku || !formData.main_price) {
        throw new Error('Please fill in all required fields');
      }

      // Prepare data for API (Note: This would need a PUT endpoint in the backend)
      const productData = {
        ...formData,
        main_price: parseFloat(formData.main_price),
        strikethrough_price: formData.strikethrough_price
          ? parseFloat(formData.strikethrough_price)
          : null,
        manufacturer_id: product.manufacturer_id || 1,
        is_active: formData.is_active,
        category_ids: formData.category_ids,
        is_featured: formData.store_type === 'Unmanned' ? formData.is_featured : false,
      };

      // TODO: Implement updateProduct API call
      // await productService.updateProduct(product.id, productData);
      console.log('Product data to update:', productData);
      
      setSuccess('Product details updated successfully!');
      
      // For now, simulate success and move to step 2
      setTimeout(() => {
        setActiveStep(1);
      }, 1000);
      
    } catch (err) {
      console.error('Error updating product:', err);
      setError(err.message || 'Failed to update product');
    } finally {
      setLoading(false);
    }
  };

  const handleStep2Submit = async () => {
    try {
      setLoading(true);
      setError(null);

      if (!selectedImage) {
        // If no new image selected, just close the modal
        setSuccess('Product updated successfully!');
        setTimeout(() => {
          onProductUpdated();
          handleClose();
        }, 1500);
        return;
      }

      await productService.uploadProductImage(product.id, selectedImage);
      
      setSuccess('Product and image updated successfully!');
      
      // Call the callback to refresh the product list
      setTimeout(() => {
        onProductUpdated();
        handleClose();
      }, 1500);
      
    } catch (err) {
      console.error('Error uploading image:', err);
      setError(err.message || 'Failed to upload image');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    // Reset form state
    setActiveStep(0);
    setSelectedImage(null);
    setImagePreview(product?.image_urls?.[0] || null);
    setError(null);
    setSuccess(null);
    setLoading(false);
    
    onClose();
  };

  const handleSkipImageUpdate = () => {
    setSuccess('Product details updated successfully!');
    setTimeout(() => {
      onProductUpdated();
      handleClose();
    }, 1500);
  };

  if (!product) return null;

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { borderRadius: '12px' }
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h5" sx={{ fontWeight: 600 }}>
            Edit Product
          </Typography>
          <IconButton onClick={handleClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>
        
        <Stepper activeStep={activeStep} sx={{ mt: 2 }}>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>
      </DialogTitle>

      <DialogContent sx={{ pt: 2 }}>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}
        
        {success && (
          <Alert severity="success" sx={{ mb: 2 }}>
            {success}
          </Alert>
        )}

        {/* Step 1: Edit Product Details */}
        {activeStep === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <TextField
              label="Product Title *"
              value={formData.title}
              onChange={handleInputChange('title')}
              fullWidth
              disabled={loading}
            />
            
            <TextField
              label="SKU *"
              value={formData.sku}
              onChange={handleInputChange('sku')}
              fullWidth
              disabled={loading}
              helperText="Unique product identifier"
            />
            
            <TextField
              label="Short Description"
              value={formData.description_short}
              onChange={handleInputChange('description_short')}
              fullWidth
              disabled={loading}
              helperText="Brief description for product cards"
            />
            
            <TextField
              label="Long Description"
              value={formData.description_long}
              onChange={handleInputChange('description_long')}
              fullWidth
              multiline
              rows={3}
              disabled={loading}
              helperText="Detailed description for product detail page"
            />
            
            <FormControl fullWidth disabled={loading}>
              <InputLabel>Store Type *</InputLabel>
              <Select
                value={formData.store_type}
                onChange={handleInputChange('store_type')}
                label="Store Type *"
              >
                <MenuItem value="Retail">Retail Store</MenuItem>
                <MenuItem value="Unmanned">Unmanned Store</MenuItem>
              </Select>
            </FormControl>
            
            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                label="Main Price *"
                value={formData.main_price}
                onChange={handleInputChange('main_price')}
                type="number"
                inputProps={{ step: '0.01', min: '0' }}
                fullWidth
                disabled={loading}
              />

              <TextField
                label="Strikethrough Price"
                value={formData.strikethrough_price}
                onChange={handleInputChange('strikethrough_price')}
                type="number"
                inputProps={{ step: '0.01', min: '0' }}
                fullWidth
                disabled={loading}
                helperText="Optional original price"
              />
            </Box>

            {/* Category Selection */}
            <CategorySelector
              selectedCategories={formData.category_ids}
              onCategoriesChange={handleCategoriesChange}
              disabled={loading}
              label="Product Categories"
            />

            {/* Featured Product Toggle - Only for Unmanned Stores */}
            {formData.store_type === 'Unmanned' && (
              <Box sx={{ mt: 2 }}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.is_featured}
                      onChange={handleInputChange('is_featured')}
                      disabled={loading}
                      color="secondary"
                    />
                  }
                  label={
                    <Box>
                      <Typography variant="body1" sx={{ fontWeight: 500 }}>
                        Add to 热门推荐 (Featured Products)
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Featured products appear prominently in the main app for unmanned stores
                      </Typography>
                    </Box>
                  }
                  sx={{ alignItems: 'flex-start' }}
                />
              </Box>
            )}

            {/* Product Status Toggle */}
            <Box sx={{ mt: 2 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.is_active}
                    onChange={handleInputChange('is_active')}
                    disabled={loading}
                    color="primary"
                  />
                }
                label={
                  <Box>
                    <Typography variant="body1" sx={{ fontWeight: 500 }}>
                      Product Status
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {formData.is_active ? 'Active - Visible to customers' : 'Inactive - Hidden from customers'}
                    </Typography>
                  </Box>
                }
                sx={{ alignItems: 'flex-start' }}
              />
            </Box>
          </Box>
        )}

        {/* Step 2: Update Image */}
        {activeStep === 1 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Typography variant="h6" sx={{ fontWeight: 600 }}>
              Update Product Image (Optional)
            </Typography>
            
            <Card variant="outlined">
              <CardContent sx={{ textAlign: 'center', py: 4 }}>
                {imagePreview ? (
                  <Box>
                    <Avatar
                      src={imagePreview}
                      sx={{ width: 120, height: 120, mx: 'auto', mb: 2 }}
                      variant="rounded"
                    />
                    <Typography variant="body2" color="text.secondary">
                      {selectedImage ? selectedImage.name : 'Current image'}
                    </Typography>
                  </Box>
                ) : (
                  <Box>
                    <UploadIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
                    <Typography variant="body1" gutterBottom>
                      No image available
                    </Typography>
                  </Box>
                )}
                
                <Button
                  variant="outlined"
                  component="label"
                  sx={{ mt: 2 }}
                  disabled={loading}
                >
                  {imagePreview ? 'Change Image' : 'Select Image'}
                  <input
                    type="file"
                    hidden
                    accept="image/*"
                    onChange={handleImageSelect}
                  />
                </Button>
              </CardContent>
            </Card>
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ p: 3, pt: 1 }}>
        <Button onClick={handleClose} disabled={loading}>
          Cancel
        </Button>
        
        {activeStep === 0 ? (
          <Button
            variant="contained"
            onClick={handleStep1Submit}
            disabled={loading || !formData.title || !formData.sku || !formData.main_price}
            startIcon={loading ? <CircularProgress size={20} /> : null}
          >
            {loading ? 'Updating...' : 'Update Details'}
          </Button>
        ) : (
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Button
              variant="outlined"
              onClick={handleSkipImageUpdate}
              disabled={loading}
            >
              Skip Image Update
            </Button>
            <Button
              variant="contained"
              onClick={handleStep2Submit}
              disabled={loading}
              startIcon={loading ? <CircularProgress size={20} /> : <SuccessIcon />}
            >
              {loading ? 'Uploading...' : 'Update Image'}
            </Button>
          </Box>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default EditProductModal;
