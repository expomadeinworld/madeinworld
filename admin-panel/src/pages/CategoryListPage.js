import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Card,
  CardContent,
  Grid,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Tabs,
  Tab,
  Divider,
  Avatar,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  ExpandMore as ExpandMoreIcon,
  Category as CategoryIcon,
  AccountTree as SubcategoryIcon,
  Store as StoreIcon,
  ShoppingBag as RetailIcon,
  SmartToy as UnmannedIcon,
  Storefront as ExhibitionIcon,
  Group as GroupBuyingIcon,
  PhotoCamera as PhotoIcon,
} from '@mui/icons-material';
import { useToast } from '../contexts/ToastContext';

const CategoryListPage = () => {
  const [categories, setCategories] = useState([]);
  const [stores, setStores] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentTab, setCurrentTab] = useState(0);
  const [openDialog, setOpenDialog] = useState(false);
  const [openSubcategoryDialog, setOpenSubcategoryDialog] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);
  const [editingSubcategory, setEditingSubcategory] = useState(null);
  const [selectedCategoryForSubcategory, setSelectedCategoryForSubcategory] = useState(null);
  const [selectedStore, setSelectedStore] = useState(null);
  const { showToast } = useToast();

  const [categoryForm, setCategoryForm] = useState({
    name: '',
    mini_app_association: [],
    store_id: null,
    is_active: true,
  });

  const [subcategoryForm, setSubcategoryForm] = useState({
    name: '',
    image_url: '',
    display_order: 0,
  });

  const miniAppTabs = [
    {
      value: 'RetailStore',
      label: '零售门店',
      icon: <RetailIcon />,
      color: '#d32f2f',
      requiresStore: false,
      description: 'Direct category management without store location'
    },
    {
      value: 'UnmannedStore',
      label: '无人商店',
      icon: <UnmannedIcon />,
      color: '#1976d2',
      requiresStore: true,
      description: 'Categories scoped by store location (无人门店 + 无人仓店)'
    },
    {
      value: 'ExhibitionSales',
      label: '展销展消',
      icon: <ExhibitionIcon />,
      color: '#7b1fa2',
      requiresStore: true,
      description: 'Categories scoped by store location (展销商店 + 展销商城)'
    },
    {
      value: 'GroupBuying',
      label: '团购团批',
      icon: <GroupBuyingIcon />,
      color: '#f57c00',
      requiresStore: false,
      description: 'Direct category management without store location'
    },
  ];

  useEffect(() => {
    fetchCategories();
    fetchStores();
  }, []);

  useEffect(() => {
    fetchCategories();
  }, [currentTab, selectedStore]);

  const fetchCategories = async () => {
    try {
      setLoading(true);
      const currentMiniApp = miniAppTabs[currentTab];
      let url = `http://localhost:8080/api/v1/categories?mini_app_type=${currentMiniApp.value}&include_subcategories=true&include_store_info=true`;

      // Add store filter for location-based mini-apps
      if (currentMiniApp.requiresStore && selectedStore) {
        url += `&store_id=${selectedStore.id}`;
      }

      const response = await fetch(url);
      if (response.ok) {
        const data = await response.json();
        setCategories(data);
      } else {
        showToast('Failed to fetch categories', 'error');
      }
    } catch (error) {
      console.error('Error fetching categories:', error);
      showToast('Error fetching categories', 'error');
    } finally {
      setLoading(false);
    }
  };

  const fetchStores = async () => {
    try {
      const currentMiniApp = miniAppTabs[currentTab];
      if (!currentMiniApp.requiresStore) return;

      const response = await fetch(`http://localhost:8080/api/v1/stores?mini_app_type=${currentMiniApp.value}`);
      if (response.ok) {
        const data = await response.json();
        setStores(data);
        // Auto-select first store if none selected
        if (data.length > 0 && !selectedStore) {
          setSelectedStore(data[0]);
        }
      } else {
        showToast('Failed to fetch stores', 'error');
      }
    } catch (error) {
      console.error('Error fetching stores:', error);
      showToast('Error fetching stores', 'error');
    }
  };

  const handleCreateCategory = async () => {
    try {
      const currentMiniApp = miniAppTabs[currentTab];
      const categoryData = {
        ...categoryForm,
        mini_app_association: [currentMiniApp.value],
        store_type_association: 'All',
        store_id: currentMiniApp.requiresStore ? selectedStore?.id : null,
      };

      const response = await fetch('http://localhost:8080/api/v1/categories', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(categoryData),
      });

      if (response.ok) {
        showToast('Category created successfully', 'success');
        setOpenDialog(false);
        resetCategoryForm();
        fetchCategories();
      } else {
        showToast('Failed to create category', 'error');
      }
    } catch (error) {
      console.error('Error creating category:', error);
      showToast('Error creating category', 'error');
    }
  };

  const handleUpdateCategory = async () => {
    try {
      const currentMiniApp = miniAppTabs[currentTab];
      const categoryData = {
        ...categoryForm,
        mini_app_association: [currentMiniApp.value],
        store_type_association: 'All',
        store_id: currentMiniApp.requiresStore ? selectedStore?.id : null,
      };

      const response = await fetch(`http://localhost:8080/api/v1/categories/${editingCategory.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(categoryData),
      });

      if (response.ok) {
        showToast('Category updated successfully', 'success');
        setOpenDialog(false);
        setEditingCategory(null);
        resetCategoryForm();
        fetchCategories();
      } else {
        showToast('Failed to update category', 'error');
      }
    } catch (error) {
      console.error('Error updating category:', error);
      showToast('Error updating category', 'error');
    }
  };



  const handleCreateSubcategory = async () => {
    try {
      const response = await fetch(`http://localhost:8080/api/v1/categories/${selectedCategoryForSubcategory.id}/subcategories`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(subcategoryForm),
      });

      if (response.ok) {
        showToast('Subcategory created successfully', 'success');
        setOpenSubcategoryDialog(false);
        setSubcategoryForm({ name: '', image_url: '', display_order: 0 });
        setSelectedCategoryForSubcategory(null);
        fetchCategories();
      } else {
        showToast('Failed to create subcategory', 'error');
      }
    } catch (error) {
      console.error('Error creating subcategory:', error);
      showToast('Error creating subcategory', 'error');
    }
  };

  const handleUpdateSubcategory = async () => {
    try {
      const response = await fetch(`http://localhost:8080/api/v1/subcategories/${editingSubcategory.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(subcategoryForm),
      });

      if (response.ok) {
        showToast('Subcategory updated successfully', 'success');
        setOpenSubcategoryDialog(false);
        setEditingSubcategory(null);
        setSubcategoryForm({ name: '', image_url: '', display_order: 0 });
        fetchCategories();
      } else {
        showToast('Failed to update subcategory', 'error');
      }
    } catch (error) {
      console.error('Error updating subcategory:', error);
      showToast('Error updating subcategory', 'error');
    }
  };

  const handleDeleteSubcategory = async (subcategoryId) => {
    if (window.confirm('Are you sure you want to delete this subcategory?')) {
      try {
        const response = await fetch(`http://localhost:8080/api/v1/subcategories/${subcategoryId}`, {
          method: 'DELETE',
        });

        if (response.ok) {
          showToast('Subcategory deleted successfully', 'success');
          fetchCategories();
        } else {
          showToast('Failed to delete subcategory', 'error');
        }
      } catch (error) {
        console.error('Error deleting subcategory:', error);
        showToast('Error deleting subcategory', 'error');
      }
    }
  };

  const handleSubcategoryImageUpload = async (subcategoryId, file) => {
    try {
      const formData = new FormData();
      formData.append('image', file);

      const response = await fetch(`http://localhost:8080/api/v1/subcategories/${subcategoryId}/image`, {
        method: 'POST',
        body: formData,
      });

      if (response.ok) {
        showToast('Subcategory image uploaded successfully', 'success');
        fetchCategories();
      } else {
        showToast('Failed to upload subcategory image', 'error');
      }
    } catch (error) {
      console.error('Error uploading subcategory image:', error);
      showToast('Error uploading subcategory image', 'error');
    }
  };

  const openSubcategoryDialogHandler = (category, subcategory = null) => {
    setSelectedCategoryForSubcategory(category);
    if (subcategory) {
      setEditingSubcategory(subcategory);
      setSubcategoryForm({
        name: subcategory.name,
        image_url: subcategory.image_url || '',
        display_order: subcategory.display_order || 0,
      });
    } else {
      setEditingSubcategory(null);
      setSubcategoryForm({ name: '', image_url: '', display_order: 0 });
    }
    setOpenSubcategoryDialog(true);
  };



  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <Typography>Loading categories...</Typography>
      </Box>
    );
  }

  const handleTabChange = (event, newValue) => {
    setCurrentTab(newValue);
    setSelectedStore(null);
    setCategories([]);
  };

  const resetCategoryForm = () => {
    setCategoryForm({
      name: '',
      mini_app_association: [],
      store_id: null,
      is_active: true,
    });
  };

  const openCategoryDialog = (category = null) => {
    if (category) {
      setEditingCategory(category);
      setCategoryForm({
        name: category.name,
        mini_app_association: category.mini_app_association,
        store_id: category.store_id,
        is_active: category.is_active,
      });
    } else {
      setEditingCategory(null);
      resetCategoryForm();
    }
    setOpenDialog(true);
  };

  const handleDeleteCategory = async (categoryId) => {
    if (window.confirm('Are you sure you want to delete this category?')) {
      try {
        const response = await fetch(`http://localhost:8080/api/v1/categories/${categoryId}`, {
          method: 'DELETE',
        });

        if (response.ok) {
          showToast('Category deleted successfully', 'success');
          fetchCategories();
        } else {
          showToast('Failed to delete category', 'error');
        }
      } catch (error) {
        console.error('Error deleting category:', error);
        showToast('Error deleting category', 'error');
      }
    }
  };

  const getMiniAppLabel = (value) => {
    const tab = miniAppTabs.find(tab => tab.value === value);
    return tab ? tab.label : value;
  };

  const currentMiniApp = miniAppTabs[currentTab];

  return (
    <Box p={3}>
      <Typography variant="h4" component="h1" mb={3}>
        Category Management
      </Typography>

      {/* Mini-App Tabs */}
      <Tabs
        value={currentTab}
        onChange={handleTabChange}
        variant="fullWidth"
        sx={{ mb: 3 }}
      >
        {miniAppTabs.map((tab, index) => (
          <Tab
            key={tab.value}
            icon={tab.icon}
            label={tab.label}
            sx={{
              color: tab.color,
              '&.Mui-selected': {
                color: tab.color,
                fontWeight: 'bold'
              }
            }}
          />
        ))}
      </Tabs>

      {/* Current Mini-App Info */}
      <Card sx={{ mb: 3, bgcolor: `${currentMiniApp.color}10` }}>
        <CardContent>
          <Box display="flex" alignItems="center" mb={2}>
            {currentMiniApp.icon}
            <Typography variant="h6" sx={{ ml: 1, color: currentMiniApp.color }}>
              {currentMiniApp.label}
            </Typography>
          </Box>
          <Typography variant="body2" color="text.secondary">
            {currentMiniApp.description}
          </Typography>
        </CardContent>
      </Card>

      {/* Store Selection for Location-Based Mini-Apps */}
      {currentMiniApp.requiresStore && (
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Typography variant="h6" mb={2}>
              Select Store Location
            </Typography>
            {stores.length === 0 ? (
              <Alert severity="warning">
                No stores found for this mini-app type. Please create stores first.
              </Alert>
            ) : (
              <Grid container spacing={2}>
                {stores.map((store) => (
                  <Grid item xs={12} sm={6} md={4} key={store.id}>
                    <Card
                      sx={{
                        cursor: 'pointer',
                        border: selectedStore?.id === store.id ? `2px solid ${currentMiniApp.color}` : '1px solid #e0e0e0',
                        '&:hover': { boxShadow: 2 }
                      }}
                      onClick={() => setSelectedStore(store)}
                    >
                      <CardContent>
                        <Box display="flex" alignItems="center">
                          <Avatar
                            src={store.image_url}
                            sx={{
                              width: 40,
                              height: 40,
                              mr: 2,
                              bgcolor: currentMiniApp.color
                            }}
                          >
                            <StoreIcon />
                          </Avatar>
                          <Box>
                            <Typography variant="subtitle1">
                              {store.name}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {store.city} • {store.type}
                            </Typography>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                  </Grid>
                ))}
              </Grid>
            )}
          </CardContent>
        </Card>
      )}

      {/* Action Bar */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          {selectedStore && (
            <Chip
              icon={<StoreIcon />}
              label={`Categories for: ${selectedStore.name}`}
              color="primary"
              variant="outlined"
            />
          )}
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => openCategoryDialog()}
          disabled={currentMiniApp.requiresStore && !selectedStore}
          sx={{ bgcolor: currentMiniApp.color }}
        >
          Add Category
        </Button>
      </Box>

      {/* Categories List */}
      {loading ? (
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="200px">
          <Typography>Loading categories...</Typography>
        </Box>
      ) : categories.length === 0 ? (
        <Alert severity="info">
          {currentMiniApp.requiresStore && !selectedStore
            ? 'Please select a store location to view categories.'
            : 'No categories found. Create your first category to get started.'
          }
        </Alert>
      ) : (
        <Grid container spacing={3}>
          {categories.map((category) => (
            <Grid item xs={12} key={category.id}>
              <Accordion>
                <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                  <Box display="flex" alignItems="center" width="100%">
                    <CategoryIcon sx={{ mr: 2, color: currentMiniApp.color }} />
                    <Box flexGrow={1}>
                      <Typography variant="h6">
                        {category.name}
                      </Typography>
                      {category.store_name && (
                        <Typography variant="caption" color="text.secondary">
                          Store: {category.store_name} ({category.store_city})
                        </Typography>
                      )}
                    </Box>
                    <Box display="flex" gap={1} mr={2}>
                      <Chip
                        label={currentMiniApp.label}
                        size="small"
                        sx={{
                          bgcolor: currentMiniApp.color,
                          color: 'white'
                        }}
                      />
                      {category.store_type && (
                        <Chip
                          label={category.store_type}
                          size="small"
                          variant="outlined"
                        />
                      )}
                    </Box>
                    <IconButton
                      size="small"
                      onClick={(e) => {
                        e.stopPropagation();
                        openCategoryDialog(category);
                      }}
                    >
                      <EditIcon />
                    </IconButton>
                    <IconButton
                      size="small"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDeleteCategory(category.id);
                      }}
                      color="error"
                    >
                      <DeleteIcon />
                    </IconButton>
                  </Box>
                </AccordionSummary>
                <AccordionDetails>
                  <Box>
                    <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                      <Typography variant="subtitle1">
                        Subcategories ({category.subcategories?.length || 0})
                      </Typography>
                      <Button
                        size="small"
                        startIcon={<AddIcon />}
                        onClick={() => openSubcategoryDialogHandler(category)}
                      >
                        Add Subcategory
                      </Button>
                    </Box>
                    
                    {category.subcategories && category.subcategories.length > 0 ? (
                      <List>
                        {category.subcategories.map((subcategory) => (
                          <ListItem key={subcategory.id}>
                            <Avatar
                              src={subcategory.image_url}
                              sx={{ mr: 2, width: 40, height: 40 }}
                            >
                              <SubcategoryIcon />
                            </Avatar>
                            <ListItemText
                              primary={subcategory.name}
                              secondary={`Order: ${subcategory.display_order}`}
                            />
                            <ListItemSecondaryAction>
                              <Tooltip title="Upload Image">
                                <IconButton size="small" component="label">
                                  <PhotoIcon />
                                  <input
                                    type="file"
                                    hidden
                                    accept="image/*"
                                    onChange={(e) => {
                                      if (e.target.files[0]) {
                                        handleSubcategoryImageUpload(subcategory.id, e.target.files[0]);
                                      }
                                    }}
                                  />
                                </IconButton>
                              </Tooltip>
                              <IconButton
                                size="small"
                                onClick={() => openSubcategoryDialogHandler(category, subcategory)}
                              >
                                <EditIcon />
                              </IconButton>
                              <IconButton
                                size="small"
                                onClick={() => handleDeleteSubcategory(subcategory.id)}
                                color="error"
                              >
                                <DeleteIcon />
                              </IconButton>
                            </ListItemSecondaryAction>
                          </ListItem>
                        ))}
                      </List>
                    ) : (
                      <Typography color="textSecondary">
                        No subcategories yet. Add one to get started.
                      </Typography>
                    )}
                  </Box>
                </AccordionDetails>
              </Accordion>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Category Dialog */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          <Box display="flex" alignItems="center">
            {currentMiniApp.icon}
            <Typography variant="h6" sx={{ ml: 1 }}>
              {editingCategory ? 'Edit Category' : 'Create Category'} - {currentMiniApp.label}
            </Typography>
          </Box>
        </DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="Category Name"
            fullWidth
            variant="outlined"
            value={categoryForm.name}
            onChange={(e) => setCategoryForm({ ...categoryForm, name: e.target.value })}
            sx={{ mb: 2 }}
          />

          {currentMiniApp.requiresStore && selectedStore && (
            <Alert severity="info" sx={{ mb: 2 }}>
              This category will be scoped to: <strong>{selectedStore.name}</strong> ({selectedStore.city})
            </Alert>
          )}

          <Box display="flex" alignItems="center" gap={1} mb={2}>
            <Typography variant="body2" color="text.secondary">
              Mini-App:
            </Typography>
            <Chip
              label={currentMiniApp.label}
              size="small"
              sx={{
                bgcolor: currentMiniApp.color,
                color: 'white'
              }}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button
            onClick={editingCategory ? handleUpdateCategory : handleCreateCategory}
            variant="contained"
          >
            {editingCategory ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Subcategory Dialog */}
      <Dialog open={openSubcategoryDialog} onClose={() => setOpenSubcategoryDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {editingSubcategory ? 'Edit Subcategory' : 'Create Subcategory'}
        </DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="Subcategory Name"
            fullWidth
            variant="outlined"
            value={subcategoryForm.name}
            onChange={(e) => setSubcategoryForm({ ...subcategoryForm, name: e.target.value })}
            sx={{ mb: 2 }}
          />
          <TextField
            margin="dense"
            label="Image URL"
            fullWidth
            variant="outlined"
            value={subcategoryForm.image_url}
            onChange={(e) => setSubcategoryForm({ ...subcategoryForm, image_url: e.target.value })}
            sx={{ mb: 2 }}
          />
          <TextField
            margin="dense"
            label="Display Order"
            type="number"
            fullWidth
            variant="outlined"
            value={subcategoryForm.display_order}
            onChange={(e) => setSubcategoryForm({ ...subcategoryForm, display_order: parseInt(e.target.value) || 0 })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenSubcategoryDialog(false)}>Cancel</Button>
          <Button
            onClick={editingSubcategory ? handleUpdateSubcategory : handleCreateSubcategory}
            variant="contained"
          >
            {editingSubcategory ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default CategoryListPage;
