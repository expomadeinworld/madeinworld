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
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  ExpandMore as ExpandMoreIcon,
  Category as CategoryIcon,
  AccountTree as SubcategoryIcon,
} from '@mui/icons-material';
import { useToast } from '../contexts/ToastContext';

const CategoryListPage = () => {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [openSubcategoryDialog, setOpenSubcategoryDialog] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);
  const [editingSubcategory, setEditingSubcategory] = useState(null);
  const [selectedCategoryForSubcategory, setSelectedCategoryForSubcategory] = useState(null);
  const { showToast } = useToast();

  const [categoryForm, setCategoryForm] = useState({
    name: '',
    mini_app_association: [],
  });

  const [subcategoryForm, setSubcategoryForm] = useState({
    name: '',
    image_url: '',
    display_order: 0,
  });

  const miniAppOptions = [
    { value: 'RetailStore', label: '零售门店' },
    { value: 'UnmannedStore', label: '无人商店' },
    { value: 'ExhibitionSales', label: '展销展消' },
    { value: 'GroupBuying', label: '团购团批' },
  ];

  useEffect(() => {
    fetchCategories();
  }, []);

  const fetchCategories = async () => {
    try {
      setLoading(true);
      const response = await fetch('http://localhost:8080/api/v1/categories?include_subcategories=true');
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

  const handleCreateCategory = async () => {
    try {
      const response = await fetch('http://localhost:8080/api/v1/categories', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(categoryForm),
      });

      if (response.ok) {
        showToast('Category created successfully', 'success');
        setOpenDialog(false);
        setCategoryForm({ name: '', mini_app_association: [] });
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
      const response = await fetch(`http://localhost:8080/api/v1/categories/${editingCategory.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(categoryForm),
      });

      if (response.ok) {
        showToast('Category updated successfully', 'success');
        setOpenDialog(false);
        setEditingCategory(null);
        setCategoryForm({ name: '', mini_app_association: [] });
        fetchCategories();
      } else {
        showToast('Failed to update category', 'error');
      }
    } catch (error) {
      console.error('Error updating category:', error);
      showToast('Error updating category', 'error');
    }
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

  const openCategoryDialog = (category = null) => {
    if (category) {
      setEditingCategory(category);
      setCategoryForm({
        name: category.name,
        mini_app_association: category.mini_app_association || [],
      });
    } else {
      setEditingCategory(null);
      setCategoryForm({ name: '', mini_app_association: [] });
    }
    setOpenDialog(true);
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

  const getMiniAppLabel = (value) => {
    const option = miniAppOptions.find(opt => opt.value === value);
    return option ? option.label : value;
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <Typography>Loading categories...</Typography>
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1">
          Category Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => openCategoryDialog()}
        >
          Add Category
        </Button>
      </Box>

      {categories.length === 0 ? (
        <Alert severity="info">
          No categories found. Create your first category to get started.
        </Alert>
      ) : (
        <Grid container spacing={3}>
          {categories.map((category) => (
            <Grid item xs={12} key={category.id}>
              <Accordion>
                <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                  <Box display="flex" alignItems="center" width="100%">
                    <CategoryIcon sx={{ mr: 2 }} />
                    <Typography variant="h6" sx={{ flexGrow: 1 }}>
                      {category.name}
                    </Typography>
                    <Box display="flex" gap={1} mr={2}>
                      {category.mini_app_association?.map((app) => (
                        <Chip
                          key={app}
                          label={getMiniAppLabel(app)}
                          size="small"
                          color="primary"
                        />
                      ))}
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
                            <SubcategoryIcon sx={{ mr: 2 }} />
                            <ListItemText
                              primary={subcategory.name}
                              secondary={`Order: ${subcategory.display_order}`}
                            />
                            <ListItemSecondaryAction>
                              <IconButton
                                size="small"
                                onClick={() => openSubcategoryDialogHandler(category, subcategory)}
                              >
                                <EditIcon />
                              </IconButton>
                              <IconButton
                                size="small"
                                onClick={() => handleDeleteSubcategory(subcategory.id)}
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
          {editingCategory ? 'Edit Category' : 'Create Category'}
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
          <FormControl fullWidth variant="outlined">
            <InputLabel>Mini-App Association</InputLabel>
            <Select
              multiple
              value={categoryForm.mini_app_association}
              onChange={(e) => setCategoryForm({ ...categoryForm, mini_app_association: e.target.value })}
              label="Mini-App Association"
              renderValue={(selected) => (
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                  {selected.map((value) => (
                    <Chip key={value} label={getMiniAppLabel(value)} size="small" />
                  ))}
                </Box>
              )}
            >
              {miniAppOptions.map((option) => (
                <MenuItem key={option.value} value={option.value}>
                  {option.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
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
