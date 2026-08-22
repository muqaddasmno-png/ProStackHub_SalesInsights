CREATE DATABASE sales_insights CHARACTER SET utf8mb4;
USE sales_insights;

CREATE TABLE Regions (
    RegionID    INT AUTO_INCREMENT PRIMARY KEY,
    RegionName  VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;
CREATE TABLE Customers (
    CustomerID   INT AUTO_INCREMENT PRIMARY KEY,
    FirstName    VARCHAR(50)  NOT NULL,
    LastName     VARCHAR(50)  NOT NULL,
    Email        VARCHAR(100) NOT NULL UNIQUE,
    RegionID     INT          NOT NULL,
    JoinDate     DATE         NOT NULL,
    FOREIGN KEY (RegionID) REFERENCES Regions(RegionID)
        ON DELETE RESTRICT   
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Products (
    ProductID    INT AUTO_INCREMENT PRIMARY KEY,
    ProductName  VARCHAR(120) NOT NULL,
    Category     VARCHAR(60)  NOT NULL,
    UnitPrice    DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Orders (
    OrderID      INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID   INT  NOT NULL,
    OrderDate    DATE NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
        ON DELETE CASCADE   
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE OrderItems (
    OrderItemID   INT AUTO_INCREMENT PRIMARY KEY,
    OrderID       INT NOT NULL,
    ProductID     INT NOT NULL,
    Quantity      INT NOT NULL,
    UnitPriceAtSale DECIMAL(10,2) NOT NULL,  
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
        ON DELETE CASCADE    
        ON UPDATE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE RESTRICT   
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_orders_customer ON Orders(CustomerID);
CREATE INDEX idx_orders_date ON Orders(OrderDate);
CREATE INDEX idx_orderitems_order ON OrderItems(OrderID);
CREATE INDEX idx_orderitems_product ON OrderItems(ProductID);
CREATE INDEX idx_customers_region ON Customers(RegionID);
