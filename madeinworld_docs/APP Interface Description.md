### **Global System & Design Principles**

These principles apply across the entire application, including all mini-programs, to ensure a cohesive brand identity and user experience.

* **Typography:**  
  * **Font Family:** **Manrope**.  
  * **Hierarchy:**  
    * **Major Headers** (e.g., "热门推荐", "消息"): Manrope **ExtraBold**, \~20-24px.  
    * **Card/Item Titles** (e.g., Product Names): Manrope **SemiBold**, \~16px.  
    * **Body & Descriptions**: Manrope **Regular**, \~12-14px.  
    * **Buttons & Tabs**: Manrope **SemiBold** or **Bold**, \~12-14px.  
* **Color Palette:**  
  * \#D92525 (**Theme Red**): Primary actions, active states, prices, notification badges.  
  * \#FFF5F5 (**Light Red**): Subtle backgrounds for selected/active elements.  
  * \#1A1A1A (**Primary Text**): All major text content.  
  * \#6A7485 (**Secondary Text**): Subtitles, descriptions, inactive states.  
  * \#F7F9FC (**Light Background**): The default background for all screens.  
  * \#FFFFFF (**White**): Card backgrounds, inputs.  
* **Core Interaction & Motion:**  
  * **Tapping Action:** Interactive elements (buttons, cards) will have a subtle scale(0.98) and opacity(0.9) transition on press to provide visual feedback.  
  * **Screen Transitions:**  
    * **Super-App \-\> Mini-App:** The Mini-App screen will **slide in from the right**, covering the Super-App frame.  
    * **Mini-App \-\> Super-App (Back):** The Mini-App screen will **slide out to the right**, revealing the Super-App frame underneath.  
    * **Within a Mini-App (e.g., List to Detail):** New screens will also **slide in from the right**.  
    * Between the **Bottom Navigation Bar** screen, these should be seamless, unnoticeable.

### ---

**1\. Super-App Main Page**

This is the main page container application that houses the core navigation and the entry points to all mini-apps.

#### **1.1. Screen: Home (首页)**

* **Scrolling Behavior:** The entire content area below the Header scrolls vertically as one unit. The decorative backdrop remains static at the top. The Bottom Navigation Bar is fixed at the bottom.  
* **Component: Decorative Backdrop**  
  * **Visuals:** A soft, radial gradient with Theme Red at 20% opacity, positioned at the top-center of the screen. It fades out completely about 30-40% down the screen. It sits *behind* all other content.  
* **Component: Header**  
  * **Layout:** A single row with elements aligned to the left and right.  
  * **Left Cluster:**  
    * **Location Pin Icon:** Theme Red stroke.  
    * **City Name based on the detected User’s location (e.g. "卢加诺"):** Primary Text color, Bold weight.  
    * **Store Selector Button that is chosen automatically based on the user location and chooses the one shop nearest to the user (e.g. "Via Nassa 店"):**  
      * **Visuals:** Pill-shaped button with Light Red background. Text and "\>" chevron are Theme Red.  
      * **Interaction:** Tapping this button navigates to the (predicted) full-screen **Locations Page,** screen that is also present in the Main Page second icon of the .  
  * **Right Element:**  
    * **Notification Bell Icon:** Primary Text color, outline style.  
* **Component: Search & Actions Bar**  
  * **Layout:** A row containing the search bar on the left and a QR icon on the right that is outside of the search bar.  
  * **Search Bar:**  
    * **Visuals:** Pill-shaped input field with a White background and a subtle grey border.  
    * **Internal Icon:** A search/magnifying glass icon, Secondary Text color, positioned on the left.  
    * **Placeholder Text:** "搜索商品...", Secondary Text color.  
    * **Interaction:** Tapping focuses the input, raises the keyboard, and likely navigates to a dedicated **Search Screen**.  
  * **QR Scanner Button:**  
    * **Visuals:** A distinct, recognizable QR code icon (28x28px), Primary Text color.  
    * **Interaction:** Tapping this button should open the device's camera in a dedicated **QR Scanning UI**.  
* **Component: Service Modules Mini-programs Grid**  
  * **Layout:** A 3-column and 2 rows grid.  
  * **Module Card (Template):**  
    * **Container:** A tappable \<a\> tag with rounded corners and a slight box-shadow.  
    * **Icon Container:** A square container with a light, colored background (e.g., bg-red-100) and rounded corners. The icon inside is a single color (e.g., Theme Red).  
    * **Text Label:** Primary Text, SemiBold weight, 12px size. It must not wrap to a second line (whitespace-nowrap).  
  * **Interaction:** Tapping on "零售门店" or "无人门店" initiates the slide-in transition to its respective Mini-App.  
* **Component: Selected Product Recommendations (热门推荐)**  
  * **Layout:** A 2-column grid below the section header.  
  * **Product Card (Template):**  
    * **Visuals:** Rounded corners, White background, subtle box-shadow.  
    * **Image:** Placeholder image with a 1:1 aspect ratio.  
    * **Product Title:** Primary Text, SemiBold.  
    * **Stock Left:** Secondary Text, Regular, Theme Red. This feature must be present and connected to the database where the stock of the products can be set. The stock shown on the mobile app would be 5 less than what it is actually in the database (used as a buffer).  
    * **Price (Strikethrough):** Secondary Text, line-through.  
    * **Price (Main):** Theme Red, Bold weight, larger font size.  
    * **Add Button ("+"):** A circular, Theme Red button with a white "+". When the user adds something to their cart, it will become a pill shaped icon with “-” on the left and “+” and the user can see how many of the same item is currently in the cart. If the user taps onto this button and it is not signed in, a pop up would prompt the user to sign in, if the user is signed in, it would take the user to the appropriate Mini-App (e.g. if the product belongs to the “无人门店” Mini-app, the interface would redirect to “无人门店” Mini-app, if the product belongs to the “无人仓店” Mini-App it would redirect to the “无人仓店” Mini-App. The product category would be decided by the database.)  
  * **Interaction:** Tapping the card navigates to the **Product Detail Page**. Tapping the "+" button adds the item to the cart and should show a small visual confirmation (e.g., the button briefly scales up and back down).  
  * **Special Note**: The length of the card should adjust based on the text of the title of the product that is present as the first line and the image size of the product image, similar to the UI design of XiaoHongShu Rednote. If the product title is for example two lines because it is longer in length, then obviously the card length would be longer than the product title of products that only takes one line.  
* **Component: Bottom Navigation Bar**  
  * **Visuals:** Fixed at the bottom of the screen with a White background and a top border.  
  * **Nav Item (Template):**  
    * **Inactive State:** Icon is outline-style, icon and label are Secondary Text.  
    * **Active State:** Icon is solid/filled, icon and label are Theme Red.  
  * **Interaction:** Tapping an item navigates to the corresponding screen. The state change is instant.

### ---

**2\. Mini-program 1: Products for Retail Store (零售门店)**

* **Transition:** This entire view slides in from the right, completely replacing the Super-App frame.  
* **Scrolling Behavior:** The content area below the header scrolls vertically. The header is sticky, remaining fixed at the top. The Mini-App's bottom navigation is also fixed.

#### **2.1. Screen: Products for Mini-app 1 (商品)**

* **Component: Header**  
  * **Left Element: Back Arrow Icon**  
    * **Visuals:** A left-pointing chevron.  
    * **Interaction:** Tapping this initiates the slide-out transition, returning the user to the Super-App Home screen.  
  * **Center Element: Search Bar**  
    * **Visuals:** Similar to the main search bar. Placeholder text reads "搜索商品...".  
  * **Right  Element: Notification Bell Icon**  
    * **Notification Bell Icon:** Identical to the Super-App's bell.  
* **Component: Category Carousel**  
  * **Visuals:** A single row of pill-shaped category buttons.  
  * **Motion:** Scrolls horizontally with native-like momentum. The scrollbar is not visible. The user can scroll and see the different categories present for this mini-app 1\.  
  * **Category Chip (Template):**  
    * **Inactive State:** White background, Secondary Text.  
    * **Active State:** Light Red background, Theme Red text.  
  * **Interaction:** Tapping a category filters the product list that would be below the category carousel.  
* **Component: Product from the Category Selection**  
  * **Layout:** A 2-column grid below the section header.  
  * **Product Card (Template):**  
    * **Visuals:** Rounded corners, White background, subtle box-shadow.  
    * **Image:** Placeholder image with a 1:1 aspect ratio.  
    * **Product Title:** Primary Text, SemiBold.  
    * **Note:** There would be no “Stock Left” display for 零售门店 and this would also be reflected from the database. Like inputting a new product and creating it, the first thing would be to select which Mini-App category the product is for. If it is for 零售门店, then there would be no option for stock counting.  
    * **Price (Strikethrough):** Secondary Text, line-through.  
    * **Price (Main):** Theme Red, Bold weight, larger font size.  
    * **Add Button ("+"):** A circular, Theme Red button with a white "+". When the user adds something to their cart, it will become a pill shaped icon with “-” on the left and “+” and the user can see how many of the same item is currently in the cart. Tapping this button increments the cart count and instantly updates the number in the cart icon.  
  * **Interaction:** Tapping the card navigates to the **Product Detail Page**. Tapping the "+" button adds the item to the cart and should show a small visual confirmation (e.g., the button briefly scales up and back down).  
  * **Special Note**: The length of the card should adjust based on the text of the title of the product that is present as the first line and the image size of the product image, similar to the UI design of XiaoHongShu Rednote. If the product title is for example two lines because it is longer in length, then obviously the card length would be longer than the product title of products that only takes one line.  
* **Component: Bottom Navigation (Retail-Specific)**  
  * **Visuals:** Fixed bar with 4 items: **商品** (Products), **消息** (Messages), **购物车** (Cart), **我的** (Me).  
  * **Interaction:** Navigates between screens *within* the Retail Store mini-app. These bottom navigation bar components are independent from the Super-app system wide navigation bar components, like the account is the same and shares user data, but 

### ---

**3\. Mini-App 2: Unmanned Store Mini-Program (无人门店)**

* **Transition:** Slides in from the right, replacing the Super-App frame.  
* **Scrolling Behavior:** Similar to the Retail Mini-App: sticky header, scrollable content, fixed bottom navigation.

#### **3.1. Screen: Unmanned Store Products (首页)**

* **Component: Header**  
  * **Left Element: Back Arrow Icon**  
    * **Interaction:** Returns to the Super-App Home screen.  
  * **Center Cluster: Location Selectors**  
    * **Visuals:** Contains both the City Name and the tappable Store Selector button, identical in function to the Super-App Home header; those get transferred here in the Mini-App.  
  * **Right Element: QR Scanner Icon**  
    * **Visuals & Interaction:** Identical to the Super-App Home's QR Scanner.  
* **Component: Category Carousel**  
  * **Visuals & Motion:** Identical in structure and behavior to the Retail Store's carousel, but they are Unmanned store mini-app specific, meaning from the database these categories are chosen to be seen here.  
* **Component: Product from the Category Selection**  
  * **Layout:** A 2-column grid below the section header.  
  * **Product Card (Template):**  
    * **Visuals:** Rounded corners, White background, subtle box-shadow.  
    * **Image:** Placeholder image with a 1:1 aspect ratio.  
    * **Product Title:** Primary Text, SemiBold.  
    * **Stock Left:** Secondary Text, Regular, Theme Red. This feature must be present and connected to the database where the stock of the products can be set. The stock shown on the mobile app would be 5 less than what it is actually in the database (used as a buffer).  
    * **Price (Strikethrough):** Secondary Text, line-through.  
    * **Price (Main):** Theme Red, Bold weight, larger font size.  
    * **Add Button ("+"):** A circular, Theme Red button with a white "+". When the user adds something to their cart, it will become a pill shaped icon with “-” on the left and “+” and the user can see how many of the same item is currently in the cart. Tapping this button increments the cart count and instantly updates the number in the cart icon.  
  * **Interaction:** Tapping the card navigates to the **Product Detail Page**. Tapping the "+" button adds the item to the cart and should show a small visual confirmation (e.g., the button briefly scales up and back down).  
  * **Special Note**: The length of the card should adjust based on the text of the title of the product that is present as the first line and the image size of the product image, similar to the UI design of XiaoHongShu Rednote. If the product title is for example two lines because it is longer in length, then obviously the card length would be longer than the product title of products that only takes one line.  
  * The products shown would correspond to the category chosen. Like when the user first clicks in the Mini-App there would be a category that is being selected for default (like the first one in the list) and then the products for that category would be shown here.  
* **Component: Bottom Navigation (Unmanned-Specific)**  
  * **Visuals:** Fixed bar with 4 items: **商品** (Products), **地点** (Location), **购物车** (Cart), **消息** (Messages), **我的** (Me).  
  * “For the mini-app interfaces, such as '无人仓店' and '无人门店', the bottom navigation bar will be implemented using a **Notched Bottom App Bar** design. The central position of this bar will be occupied by a large, circular, and elevated **Floating Action Button (FAB)**, which will function as the primary action for that mini-app (e.g., the Shopping Cart). This FAB must be styled with our `Theme Red` background (\#D92525) and will be 'cradled' by the navigation bar, causing the bar itself to have a concave dip in the middle. The button will protrude slightly upwards into the main content area, creating a prominent focal point. This distinct navigation bar style is exclusive to the mini-apps to differentiate their user experience from the main super-app shell and should support displaying a notification badge to indicate the number of items in the cart.”

### ---

**4\. Screens (Detailed Breakdown)**

* **Product Detail Page (PDP):**  
  * **Transition:** Slides in from the right when a product card is tapped.  
  * **Layout:**  
    * **Header:** Back Arrow, maybe a "Share" or "Favorite" icon.  
    * **Image Gallery:** A large, horizontally swipeable carousel of product images at the top.  
    * **Info Block:** Product Title, Price, detailed multi-line description.  
    * **Quantity Selector:** A component with "-" and "+" buttons and a number in the middle to adjust quantity.  
    * **Description:** Secondary text, highly visible so choose colour that is visible against the background.  
    * **"Add to Cart" Button:** A large, prominent Theme Red button at the bottom of the screen.  
* **Shopping Cart Page:**  
  * **Transition:** Slides in from the right when the cart icon is tapped.  
  * **Layout:**  
    * **Header:** Back Arrow, Title ("购物车").  
    * **Item List:** A scrollable list of products in the cart. Each row shows the product image, name, price, and a quantity selector.  
    * **Summary Section:** Displays Subtotal, Taxes, and a final Total.  
    * **"Proceed to Checkout" Button:** A large Theme Red button.  
* **QR Scanner Page:**  
  * **Transition:** A modal transition (fades in or slides up) that opens the camera.  
  * **Layout:** A full-screen camera view with a semi-transparent overlay. A square guide box is centered to help the user frame the QR code. There will be a "Close" button.