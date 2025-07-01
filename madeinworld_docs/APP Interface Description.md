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
* **For store locations, location pins:**  
  * \#2196f3 \- Light blue (无人门店)  
  * \#4caf50 \- Light green (无人仓店)  
  * \#ffd556 \- Light yellow (展销商店)  
  * \#f38900 \- Vivid Orange (展销商城)  
* **Core Interaction & Motion:**  
  * **Tapping Action:** Interactive elements (buttons, cards) will have a subtle scale(0.98) and opacity(0.9) transition on press to provide visual feedback.  
  * **Screen Transitions:**  
    * **Super-App \-\> Mini-App:** The Mini-App screen will **slide in from the bottom**, covering the Super-App frame and appear.  
    * **Mini-App \-\> Super-App (Back):** The Mini-App screen will **slide down to the bottom**, revealing the Super-App frame underneath and disappearing.  
    * **Within a Mini-App (e.g., List to Detail):** New screens should **slide in from the right**.  
    * **Return to the previous screen:** When there is a chevron icon pointing to the left (the back icon) the transition should be that the current screen **sliding out to the right (right sliding motion) and the previous screen or whatever screen the screen is designed to return to should appear underneath.**  
    * Between the **Bottom Navigation Bar** screen, these should be seamless, unnoticeable.

### ---

**1\. Super-App Main Page**

This is the main page container application that houses the core navigation and the entry points to all mini-apps.

#### **1.1. Screen: Home (首页)**

* **Scrolling Behavior:** The entire content area below the Header scrolls vertically as one unit. The decorative backdrop remains static at the top. The Bottom Navigation Bar is fixed at the bottom.  
* **Component: Decorative Backdrop**  
  * **Visuals:** A soft, radial gradient with Theme Red at 20% opacity, positioned at the top-center of the screen. It fades out completely about 40-50% down the screen. It sits *behind* all other content. This should give an elegant feel for the users, like a sunset or a golden hour vibe. Should be majestic and take quite a bit of room in the main page of the app.  
* **Component: Header**  
  * **Layout:** A single row with elements aligned to the left and right.  
  * **Left Cluster:**  
    * **Location Pin Icon:** Theme Red stroke.  
    * **City Name based on the detected User’s location (e.g. "卢加诺"):** Primary Text color, Bold weight.  
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
    * **Visuals:** A distinct, recognizable QR code icon (28x28px), Primary Text color. Simple icon, nothing too complex visually.   
    * **Interaction:** Tapping this button should open the device's camera in a dedicated **QR Scanning UI**.  
* **Component: Service Modules Mini-programs Grid**  
  * **Layout:** A 2-column and 2 rows grid.  
  * **Module Card (Template):**  
    * **Container:** A tappable \<a\> tag with rounded corners and a slight box-shadow.  
    * **Icon Container:** A square container with a light, colored background (e.g., bg-red-100) and rounded corners. The icon inside is a single color (e.g., Theme Red).  
    * **Text Label:** Primary Text, SemiBold weight, 12px size. It must not wrap to a second line (whitespace-nowrap).  
  * **Interaction:** Tapping on the mini-app programs initiates the slide-in transition to its respective Mini-App (the screen should slide in from the bottom).  
* **Component: Selected Product Recommendations (热门推荐)**  
  * **Layout:** A 2-column grid below the section header.  
  * **Product Card (Template):**  
    * **Visuals:** Rounded corners, White background, subtle box-shadow.  
    * **Image:** Placeholder image with a 1:1 aspect ratio.  
    * **Product Title:** Primary Text, SemiBold.  
    * **Stock Left:** Secondary Text, Regular, Theme Red. This feature must be present and connected to the database where the stock of the products can be set. The stock shown on the mobile app would be **5 less than** what it is actually in the database (**used as a buffer**).  
    * **Price (Strikethrough):** Secondary Text, line-through.  
    * **Price (Main):** Theme Red, Bold weight, larger font size.  
    * **Add Button ("+"):** A circular, Theme Red button with a white "+". When the user adds something to their cart, it will become a pill shaped icon with “-” on the left and “+” and the user can see how many of the same item is currently in the cart. If the user taps onto this button and it is not signed in, a pop up would prompt the user to sign in, if the user is signed in, it would take the user to the appropriate Mini-App (e.g. if the product belongs to the “无人商店” Mini-app, the interface would redirect to “无人商店” Mini-app, if the product belongs to the “展销展消” Mini-App it would redirect to the “展销展消” Mini-App. The product category would be decided by the database.)  
  * **Interaction:** Tapping the card navigates to the **Product Detail Page**. Tapping the "+" button adds the item to the cart and should show a small visual confirmation (e.g., the button briefly scales up and back down).  
  * **Special Note**: The length of the card should adjust based on the text of the title of the product that is present as the first line and the image size of the product image, similar to the UI design of XiaoHongShu Rednote. If the product title is for example two lines because it is longer in length, then obviously the card length would be longer than the product title of products that only takes one line.  
* **Component: Bottom Navigation Bar**  
  * **Visuals:** Fixed at the bottom of the screen with a White background and a top border.  
  * **Nav Item (Template):**  
    * **Inactive State:** Icon is outline-style, icon and label are Secondary Text.  
    * **Active State:** Icon is solid/filled, icon and label are Theme Red.  
  * **Interaction:** Tapping an item navigates to the corresponding screen. The state change is instant.