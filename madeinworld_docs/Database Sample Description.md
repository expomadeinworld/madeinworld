### **Core Database Schema Design**

Below are the essential database tables, their columns, and the relationships between them.

#### **1\. User & Stakeholder Tables**

These tables manage identity, roles, and permissions.

* **Users**  
  * user\_id (Primary Key, UUID)  
  * phone\_number (VARCHAR, Unique) \- For login/authentication.  
  * password\_hash (VARCHAR)  
  * full\_name (VARCHAR)  
  * email (VARCHAR, Nullable)  
  * avatar\_url (VARCHAR, Nullable)  
  * role (ENUM: 'Customer', 'Admin', 'Manufacturer', '3PL', 'Partner') \- Defines user's access level.  
  * created\_at (TIMESTAMP)  
  * last\_login (TIMESTAMP)  
* **Manufacturers** (Company profiles for manufacturers)  
  * manufacturer\_id (Primary Key, INT)  
  * company\_name (VARCHAR, Unique)  
  * contact\_person (VARCHAR)  
  * contact\_email (VARCHAR)  
  * address (TEXT)  
  * *A User with the 'Manufacturer' role will be linked to a record here via a joining table.*  
* **Partners** (Profiles for partners managing unmanned stores)  
  * partner\_id (Primary Key, INT)  
  * user\_id (Foreign Key to Users) \- Links the partner profile to a user login.  
  * region\_assigned (VARCHAR, Nullable)  
  * *A partner can be assigned to one or more unmanned stores.*

#### **2\. Store & Product Catalog Tables**

These tables define what is being sold and where.

* **Stores**  
  * store\_id (Primary Key, INT)  
  * name (VARCHAR, e.g., "Via Nassa 店")  
  * city (VARCHAR, e.g., "卢加诺")  
  * address (TEXT)  
  * latitude (DECIMAL)  
  * longitude (DECIMAL)  
  * type (ENUM: 'Retail', 'Unmanned', 'Warehouse') \- Critical for filtering products and features.  
  * is\_active (BOOLEAN)  
* **Product\_Categories**  
  * category\_id (Primary Key, INT)  
  * name (VARCHAR, e.g., "Beverages", "Snacks")  
  * store\_type\_association (ENUM: 'Retail', 'Unmanned', 'All') \- Determines in which mini-app's carousel this category appears.  
* **Products**  
  * product\_id (Primary Key, INT)  
  * sku (VARCHAR, Unique) \- Stock Keeping Unit.  
  * title (VARCHAR) \- The product name.  
  * description\_short (VARCHAR) \- The subtitle on the card.  
  * description\_long (TEXT) \- For the Product Detail Page.  
  * manufacturer\_id (Foreign Key to Manufacturers) \- Links product to its manufacturer.  
  * store\_type (ENUM: 'Retail', 'Unmanned') \- Determines the product's home mini-app and associated logic (e.g., stock display).  
  * main\_price (DECIMAL)  
  * strikethrough\_price (DECIMAL, Nullable)  
  * is\_active (BOOLEAN)  
  * is\_featured (BOOLEAN) \- To identify products for "热门推荐".  
* **Product\_Images** (Allows for multiple images per product)  
  * image\_id (Primary Key, INT)  
  * product\_id (Foreign Key to Products)  
  * image\_url (VARCHAR)  
  * display\_order (INT) \- 0 for the main card image, 1, 2, 3 for the PDP gallery.  
* **Product\_Category\_Mapping** (Many-to-Many relationship)  
  * product\_id (Foreign Key to Products)  
  * category\_id (Foreign Key to Product\_Categories)

#### **3\. Inventory & Order Management Tables**

This is the core operational schema, including the logistics flow.

* **Inventory** (Tracks the real stock quantity)  
  * inventory\_id (Primary Key, INT)  
  * product\_id (Foreign Key to Products)  
  * store\_id (Foreign Key to Stores) \- Crucially links stock to a specific unmanned store.  
  * quantity (INT) \- The **actual** number of items in the store. The (stock \- 5\) buffer is a **business rule applied in the API**, not stored here.  
* **Stock\_Requests** (The start of the logistics chain)  
  * request\_id (Primary Key, INT)  
  * product\_id (Foreign Key to Products)  
  * quantity\_requested (INT)  
  * manufacturer\_id (Foreign Key to Manufacturers)  
  * destination\_store\_id (Foreign Key to Stores)  
  * requesting\_admin\_id (Foreign Key to Users)  
  * status (ENUM: 'Pending', 'Confirmed by Manufacturer', 'Ready for Pickup', 'In Transit', 'Delivered', 'Verified', 'Cancelled')  
  * created\_at (TIMESTAMP)  
* **Shipments** (Managed by 3PL)  
  * shipment\_id (Primary Key, INT)  
  * request\_id (Foreign Key to Stock\_Requests)  
  * assigned\_3pl\_id (Foreign Key to Users)  
  * pickup\_timestamp (TIMESTAMP, Nullable)  
  * delivery\_timestamp (TIMESTAMP, Nullable)  
  * status (ENUM: 'Assigned', 'Picked Up', 'Delivered')  
* **Stock\_Verifications** (Managed by Partners)  
  * verification\_id (Primary Key, INT)  
  * shipment\_id (Foreign Key to Shipments)  
  * verifying\_partner\_id (Foreign Key to Users)  
  * quantity\_verified (INT)  
  * discrepancy\_notes (TEXT, Nullable) \- Used if quantity\_verified \!= quantity\_requested.  
  * verified\_at (TIMESTAMP)  
* **Carts** and **Cart\_Items**  
  * Used to manage the customer's shopping cart. It links a user\_id, product\_id, and quantity.  
* **Orders** and **Order\_Items**  
  * Created upon successful checkout. Captures a snapshot of the purchase, including price, quantity, user, and shipping/store details.  
* **Notifications**  
  * notification\_id (Primary Key, INT)  
  * recipient\_user\_id (Foreign Key to Users)  
  * title (VARCHAR)  
  * message (TEXT)  
  * reference\_type (ENUM: 'StockRequest', 'Shipment', 'Order')  
  * reference\_id (INT) \- e.g., the request\_id or shipment\_id.  
  * is\_read (BOOLEAN)  
  * created\_at (TIMESTAMP)

### ---

**Stakeholder-Specific Functionalities & Interfaces**

Each stakeholder logs into a web-based or dedicated backend interface powered by the same database but with different views and permissions.

#### **1\. Admin Interface**

The Admin has god-mode access.

* **Dashboard:** A comprehensive overview of total sales, inventory levels across all unmanned stores, pending stock requests, and in-transit shipments.  
* **User Management:** Full CRUD (Create, Read, Update, Delete) on the Users table. Can create new accounts for Manufacturers, 3PL, and Partners and assign them their roles and link them to their respective company/profile tables.  
* **Store Management:** CRUD on the Stores table. Can add new stores, set their type ('Retail'/'Unmanned'), and crucially, assign one or more Partners to each unmanned store via a mapping table.  
* **Product & Catalog Management:**  
  * Full CRUD on Products and Product\_Categories.  
  * **Adding a Product (Detailed Flow):**  
    1. Enter SKU, Title, Descriptions.  
    2. Select the Manufacturer from a dropdown list (populated from the Manufacturers table).  
    3. **Crucially, select the store\_type ('Retail' or 'Unmanned').**  
    4. If 'Retail' is selected, the stock/inventory fields are hidden in the UI.  
    5. If 'Unmanned' is selected, an initial inventory count for a specific store can be set.  
    6. Assign the product to one or more Product\_Categories.  
    7. Set main\_price and strikethrough\_price.  
    8. Upload one or more images, which populates the Product\_Images table.  
* **Inventory Control:**  
  * The **primary initiator** of the supply chain. The Admin creates a new Stock\_Request, selecting a product, quantity, and destination unmanned store.  
  * Monitors the end-to-end status of all Stock\_Requests. Receives automated notifications for key events (e.g., 'Ready for Pickup', 'Delivered', and especially 'Discrepancy Reported by Partner').

#### **2\. Manufacturer Interface**

This interface is focused solely on fulfilling stock requests.

* **Dashboard:** A clean list of Stock\_Requests assigned to them, bucketed by status ('Pending', 'Confirmed', 'Ready for Pickup').  
* **Request Management:**  
  1. A new 'Pending' request appears on their dashboard. An email/push notification is triggered.  
  2. They review the request (product, quantity).  
  3. They change the status to 'Confirmed by Manufacturer', indicating they have the stock and are preparing it.  
  4. Once the goods are packaged and ready for transit, they change the status to **'Ready for Pickup'**. This is their final action.  
* **Backend Logic:** Changing the status to 'Ready for Pickup' automatically creates a new Notification for all users with the '3PL' role.

#### **3\. 3PL (Third-Party Logistics) Interface**

This interface is a logistics queue.

* **Dashboard:** A view of all shipments, primarily showing requests with the status 'Ready for Pickup'.  
* **Shipment Management:**  
  1. A 3PL user "claims" a job from the 'Ready for Pickup' list. This assigns their user\_id to the newly created Shipment record and updates its status to 'Assigned'.  
  2. Upon collecting the goods from the manufacturer, they update the shipment status to **'Picked Up'**. The pickup\_timestamp is recorded.  
  3. Upon arriving at the destination unmanned store and handing over the goods to the Partner, they update the status to **'Delivered'**. The delivery\_timestamp is recorded.  
* **Backend Logic:** Changing the status to 'Delivered' automatically creates a Notification for the specific Partner(s) assigned to that destination store.

#### **4\. Partner Interface**

This interface is for on-site verification and store management.

* **Dashboard:** A list of incoming ('Picked Up') and delivered ('Delivered') shipments for their assigned store(s).  
* **Stock Verification (The Critical Workflow):**  
  1. A 'Delivered' shipment appears as a pending task.  
  2. The Partner opens the task, which displays the expected product and quantity from the original Stock\_Request.  
  3. They physically count the items received.  
  4. They submit a Stock\_Verification form, entering the **actual quantity counted**.  
  5. If the count matches, the process is complete.  
  6. If the count does not match, they enter the counted number and **must fill out the discrepancy\_notes field**.  
* **Backend Logic:** On submission of the verification form:  
  * The Stock\_Request status is updated to 'Verified'.  
  * The system updates the Inventory table, **adding the quantity\_verified to the existing quantity** for that product\_id at that store\_id.  
  * If a discrepancy was noted, a high-priority Notification is sent to the Admin.  
* **Store Issue Reporting:** A simple form to report urgent matters (e.g., "Freezer broken at Via Nassa store"). Submitting this creates a high-priority Notification for the Admin.