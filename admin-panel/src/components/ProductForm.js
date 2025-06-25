import React, { useState } from 'react';
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
  FormControlLabel,
  Switch,
} from '@mui/material';
import {
  CloudUpload as UploadIcon,
  CheckCircle as SuccessIcon,
} from '@mui/icons-material';
import { productService } from '../services/api';
import CategorySelector from './CategorySelector';

const steps = ['Create Product', 'Upload Image'];

const ProductForm = ({ open, onClose, onProductCreated }) => {
  const [activeStep, setActiveStep] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  
  // Form data
  const [formData, setFormData] = useState({
    title: '',
    sku: '',
    description_short: '',
    description_long: '',
    store_type: 'Unmanned',
    main_price: '',
    strikethrough_price: '',
    is_featured: false,
    is_active: true, // Default to active
    category_ids: [], // Array of category IDs
  });
  
  // Step 2 data
  const [productId, setProductId] = useState(null);
  const [selectedImage, setSelectedImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);

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

      // Prepare data for API
      const productData = {
        ...formData,
        main_price: parseFloat(formData.main_price),
        strikethrough_price: formData.strikethrough_price
          ? parseFloat(formData.strikethrough_price)
          : null,
        manufacturer_id: 1, // Default manufacturer for now
        is_active: formData.is_active,
        category_ids: formData.category_ids,
        is_featured: formData.store_type === 'Unmanned' ? formData.is_featured : false,
      };

      const response = await productService.createProduct(productData);
      
      setProductId(response.product_id);
      setSuccess('Product created successfully! Now upload an image.');
      setActiveStep(1);
      
    } catch (err) {
      console.error('Error creating product:', err);
      setError(err.message || 'Failed to create product');
    } finally {
      setLoading(false);
    }
  };

  const handleStep2Submit = async () => {
    try {
      setLoading(true);
      setError(null);

      if (!selectedImage) {
        throw new Error('Please select an image to upload');
      }

      await productService.uploadProductImage(productId, selectedImage);
      
      setSuccess('Product and image uploaded successfully!');
      
      // Call the callback to refresh the product list
      setTimeout(() => {
        onProductCreated();
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
    setFormData({
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
    setProductId(null);
    setSelectedImage(null);
    setImagePreview(null);
    setError(null);
    setSuccess(null);
    setLoading(false);
    
    onClose();
  };

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
        <Typography variant="h5" sx={{ fontWeight: 600 }}>
          Add New Product
        </Typography>
        
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

        {/* Step 1: Create Product */}
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

        {/* Step 2: Upload Image */}
        {activeStep === 1 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Typography variant="h6" sx={{ fontWeight: 600 }}>
              Upload Product Image
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
                      {selectedImage?.name}
                    </Typography>
                  </Box>
                ) : (
                  <Box>
                    <UploadIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
                    <Typography variant="body1" gutterBottom>
                      Select an image for your product
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Recommended: 300x300px, JPG or PNG
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
            {loading ? 'Creating...' : '1. Create Product'}
          </Button>
        ) : (
          <Button
            variant="contained"
            onClick={handleStep2Submit}
            disabled={loading || !selectedImage}
            startIcon={loading ? <CircularProgress size={20} /> : <SuccessIcon />}
          >
            {loading ? 'Uploading...' : '2. Upload Image'}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default ProductForm;
