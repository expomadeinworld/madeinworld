import { test, expect } from '@playwright/test';

test.describe('Enhanced Product CRUD with Mini-App Features', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the admin panel
    await page.goto('http://localhost:3000');
    
    // Wait for the page to load
    await page.waitForLoadState('networkidle');
    
    // Navigate to Products page
    await page.click('text=Products');
    await page.waitForSelector('[data-testid="product-list"]', { timeout: 10000 });
  });

  test('should create a new product with all enhanced features', async ({ page }) => {
    // Click Add Product button
    await page.click('button:has-text("Add Product")');
    
    // Wait for the product form dialog to open
    await page.waitForSelector('text=Add New Product');
    
    // Fill in basic product information
    await page.fill('input[label="Product Title *"]', 'Test Enhanced Product');
    await page.fill('input[label="SKU *"]', 'TEST-ENH-001');
    await page.fill('textarea[label="Product Description"]', 'This is a comprehensive test product with all enhanced features including stock management and mini-app recommendations.');
    
    // Test Mini-App Type Selection and Conditional Logic
    await page.click('div[label="Mini-APP Type *"]');
    await page.click('text=无人商店');
    
    // Verify that store selection appears for 无人商店
    await page.waitForSelector('div[label="Store Location *"]', { timeout: 5000 });
    
    // Select a store (assuming "Cassarate 无人门店" exists)
    await page.click('div[label="Store Location *"]');
    await page.click('text=Cassarate 无人门店');
    
    // Fill in pricing and stock information
    await page.fill('input[label="Main Price *"]', '15.99');
    await page.fill('input[label="Strikethrough Price"]', '19.99');
    await page.fill('input[label="Stock"]', '100');
    
    // Wait for categories to load and select a category
    await page.waitForSelector('div[label="Category *"]', { timeout: 10000 });
    await page.click('div[label="Category *"]');
    
    // Select the first available category
    const firstCategory = await page.locator('ul[role="listbox"] li').first();
    await firstCategory.click();
    
    // Wait for subcategories to load if available
    try {
      await page.waitForSelector('div[label="Subcategory"]', { timeout: 5000 });
      await page.click('div[label="Subcategory"]');
      const firstSubcategory = await page.locator('ul[role="listbox"] li').first();
      await firstSubcategory.click();
    } catch (error) {
      console.log('No subcategories available, continuing...');
    }
    
    // Enable both recommendation toggles
    // Main Page Featured toggle (should be visible for 无人商店)
    const mainPageToggle = page.locator('text=Add to 热门推荐 (Main Page Featured)').locator('..').locator('input[type="checkbox"]');
    await mainPageToggle.check();
    
    // Mini-App Recommendation toggle
    const miniAppToggle = page.locator('text=Mini-App Recommendation').locator('..').locator('input[type="checkbox"]');
    await miniAppToggle.check();
    
    // Submit the form
    await page.click('button:has-text("Create Product")');
    
    // Wait for success message
    await page.waitForSelector('text=Product created successfully!', { timeout: 10000 });
    
    // Proceed to image upload step
    await page.waitForSelector('text=Upload Image');
    
    // Upload a test image (create a simple test file)
    const testImagePath = './tests/fixtures/test-product-image.jpg';
    
    // Create a simple test image file if it doesn't exist
    try {
      await page.setInputFiles('input[type="file"]', testImagePath);
    } catch (error) {
      console.log('Test image not found, skipping image upload...');
    }
    
    // Complete the product creation
    await page.click('button:has-text("Upload Image")');
    
    // Wait for final success message
    await page.waitForSelector('text=Product and image uploaded successfully!', { timeout: 10000 });
    
    // Verify the dialog closes
    await page.waitForSelector('text=Add New Product', { state: 'hidden', timeout: 5000 });
  });

  test('should test conditional store selection logic', async ({ page }) => {
    // Click Add Product button
    await page.click('button:has-text("Add Product")');
    await page.waitForSelector('text=Add New Product');
    
    // Test 零售门店 (should not show store selection)
    await page.click('div[label="Mini-APP Type *"]');
    await page.click('text=零售门店');
    
    // Verify store selection is not visible
    await expect(page.locator('div[label="Store Location *"]')).not.toBeVisible();
    
    // Test 团购团批 (should not show store selection)
    await page.click('div[label="Mini-APP Type *"]');
    await page.click('text=团购团批');
    
    // Verify store selection is not visible
    await expect(page.locator('div[label="Store Location *"]')).not.toBeVisible();
    
    // Test 无人商店 (should show store selection)
    await page.click('div[label="Mini-APP Type *"]');
    await page.click('text=无人商店');
    
    // Verify store selection appears
    await page.waitForSelector('div[label="Store Location *"]', { timeout: 5000 });
    
    // Test 展销展消 (should show store selection)
    await page.click('div[label="Mini-APP Type *"]');
    await page.click('text=展销展消');
    
    // Verify store selection appears
    await page.waitForSelector('div[label="Store Location *"]', { timeout: 5000 });
    
    // Close the dialog
    await page.click('button:has-text("Cancel")');
  });

  test('should test recommendation toggles visibility', async ({ page }) => {
    // Click Add Product button
    await page.click('button:has-text("Add Product")');
    await page.waitForSelector('text=Add New Product');
    
    // Test 零售门店 (should only show Mini-App Recommendation)
    await page.click('div[label="Mini-APP Type *"]');
    await page.click('text=零售门店');
    
    // Mini-App Recommendation should be visible
    await expect(page.locator('text=Mini-App Recommendation')).toBeVisible();
    
    // Main Page Featured should not be visible
    await expect(page.locator('text=Add to 热门推荐 (Main Page Featured)')).not.toBeVisible();
    
    // Test 无人商店 (should show both toggles)
    await page.click('div[label="Mini-APP Type *"]');
    await page.click('text=无人商店');
    
    // Both toggles should be visible
    await expect(page.locator('text=Mini-App Recommendation')).toBeVisible();
    await expect(page.locator('text=Add to 热门推荐 (Main Page Featured)')).toBeVisible();
    
    // Test 展销展消 (should show both toggles)
    await page.click('div[label="Mini-APP Type *"]');
    await page.click('text=展销展消');
    
    // Both toggles should be visible
    await expect(page.locator('text=Mini-App Recommendation')).toBeVisible();
    await expect(page.locator('text=Add to 热门推荐 (Main Page Featured)')).toBeVisible();
    
    // Close the dialog
    await page.click('button:has-text("Cancel")');
  });

  test('should edit an existing product with enhanced features', async ({ page }) => {
    // Find and click edit button for the first product
    const editButton = page.locator('[data-testid="edit-product-button"]').first();
    await editButton.click();
    
    // Wait for edit dialog to open
    await page.waitForSelector('text=Edit Product');
    
    // Verify form is populated with existing data
    const titleField = page.locator('input[label="Product Title *"]');
    await expect(titleField).not.toHaveValue('');
    
    // Test changing mini-app type and verify conditional logic
    await page.click('div[label="Mini-APP Type *"]');
    await page.click('text=无人商店');
    
    // Verify store selection appears
    await page.waitForSelector('div[label="Store Location *"]', { timeout: 5000 });
    
    // Update stock value
    await page.fill('input[label="Stock"]', '75');
    
    // Enable mini-app recommendation
    const miniAppToggle = page.locator('text=Mini-App Recommendation').locator('..').locator('input[type="checkbox"]');
    await miniAppToggle.check();
    
    // Submit the changes
    await page.click('button:has-text("Update Product")');
    
    // Wait for success message
    await page.waitForSelector('text=Product details updated successfully!', { timeout: 10000 });
    
    // Verify dialog closes
    await page.waitForSelector('text=Edit Product', { state: 'hidden', timeout: 5000 });
  });

  test('should validate required fields and show appropriate errors', async ({ page }) => {
    // Click Add Product button
    await page.click('button:has-text("Add Product")');
    await page.waitForSelector('text=Add New Product');
    
    // Try to submit without required fields
    await page.click('button:has-text("Create Product")');
    
    // Should show validation error
    await page.waitForSelector('text=Please fill in all required fields', { timeout: 5000 });
    
    // Fill in title and SKU but leave price empty
    await page.fill('input[label="Product Title *"]', 'Test Product');
    await page.fill('input[label="SKU *"]', 'TEST-001');
    
    // Try to submit again
    await page.click('button:has-text("Create Product")');
    
    // Should still show validation error
    await page.waitForSelector('text=Please fill in all required fields', { timeout: 5000 });
    
    // Test mini-app specific validation
    await page.click('div[label="Mini-APP Type *"]');
    await page.click('text=无人商店');
    
    // Fill in price but don't select store
    await page.fill('input[label="Main Price *"]', '10.00');
    
    // Try to submit
    await page.click('button:has-text("Create Product")');
    
    // Should show store selection error
    await page.waitForSelector('text=Please select a store for this mini-app type', { timeout: 5000 });
    
    // Close the dialog
    await page.click('button:has-text("Cancel")');
  });
});
