const { chromium } = require('playwright');

async function testAdminPanel() {
    console.log('🚀 Starting Admin Panel Tests...\n');
    
    const browser = await chromium.launch({ headless: false });
    const page = await browser.newPage();
    
    try {
        // Test 1: Dashboard Page
        console.log('📊 Testing Dashboard Page...');
        await page.goto('http://localhost:3000');
        await page.waitForTimeout(3000); // Wait for API calls
        
        const dashboardTitle = await page.textContent('h1');
        console.log(`✅ Dashboard loaded: ${dashboardTitle}`);
        
        // Check for error messages
        const errorElements = await page.$$('text=Failed to load');
        if (errorElements.length > 0) {
            console.log('❌ Found error messages on dashboard');
        } else {
            console.log('✅ No error messages found on dashboard');
        }
        
        // Test 2: Orders Page
        console.log('\n📋 Testing Orders Page...');
        await page.click('text=Orders');
        await page.waitForTimeout(3000); // Wait for API calls
        
        const ordersTitle = await page.textContent('h1');
        console.log(`✅ Orders page loaded: ${ordersTitle}`);
        
        // Check if orders are displayed
        const orderRows = await page.$$('tbody tr');
        console.log(`✅ Found ${orderRows.length} order rows`);
        
        // Test 3: Products Page
        console.log('\n📦 Testing Products Page...');
        await page.click('text=Products');
        await page.waitForTimeout(3000); // Wait for API calls
        
        const productsTitle = await page.textContent('h1');
        console.log(`✅ Products page loaded: ${productsTitle}`);
        
        // Check if products are displayed
        const productCards = await page.$$('.product-card, .card, [data-testid="product"]');
        console.log(`✅ Found ${productCards.length} product elements`);
        
        // Test 4: Stores Page
        console.log('\n🏪 Testing Stores Page...');
        await page.click('text=Stores');
        await page.waitForTimeout(3000); // Wait for API calls
        
        const storesTitle = await page.textContent('h1');
        console.log(`✅ Stores page loaded: ${storesTitle}`);
        
        // Check if stores are displayed
        const storeCards = await page.$$('.store-card, .card, [data-testid="store"]');
        console.log(`✅ Found ${storeCards.length} store elements`);
        
        console.log('\n🎉 All tests completed successfully!');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
    } finally {
        await browser.close();
    }
}

testAdminPanel();
