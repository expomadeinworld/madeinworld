const { chromium } = require('playwright');

async function simpleTest() {
    console.log('🔍 Simple Admin Panel Test...\n');
    
    const browser = await chromium.launch({ headless: false });
    const page = await browser.newPage();
    
    try {
        console.log('📱 Navigating to admin panel...');
        await page.goto('http://localhost:3000');
        await page.waitForTimeout(5000); // Wait longer for loading
        
        // Get page title
        const title = await page.title();
        console.log(`📄 Page title: ${title}`);
        
        // Get page content
        const bodyText = await page.textContent('body');
        console.log(`📝 Page contains text: ${bodyText.substring(0, 200)}...`);
        
        // Check for specific elements
        const hasNavigation = await page.$('nav') !== null;
        console.log(`🧭 Has navigation: ${hasNavigation}`);
        
        const hasSidebar = await page.$('.sidebar, [data-testid="sidebar"]') !== null;
        console.log(`📋 Has sidebar: ${hasSidebar}`);
        
        // Check for error messages
        const errorText = await page.textContent('body');
        if (errorText.includes('Failed to load') || errorText.includes('Error')) {
            console.log('❌ Found error messages in page');
        } else {
            console.log('✅ No obvious error messages found');
        }
        
        // Take a screenshot
        await page.screenshot({ path: 'admin-panel-screenshot.png' });
        console.log('📸 Screenshot saved as admin-panel-screenshot.png');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
    } finally {
        await browser.close();
    }
}

simpleTest();
