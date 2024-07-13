-- Check if the database exists and drop it if it does
IF DB_ID('HospitalityManagement') IS NOT NULL
    DROP DATABASE HospitalityManagement;
GO

-- Create the database
CREATE DATABASE HospitalityManagement;
GO

USE HospitalityManagement;
GO

-- Drop the tables if they exist
IF OBJECT_ID('Users', 'U') IS NOT NULL
    DROP TABLE Users;
IF OBJECT_ID('Hotels', 'U') IS NOT NULL
    DROP TABLE Hotels;
IF OBJECT_ID('Rooms', 'U') IS NOT NULL
    DROP TABLE Rooms;
IF OBJECT_ID('Reservations', 'U') IS NOT NULL
    DROP TABLE Reservations;
IF OBJECT_ID('Bills', 'U') IS NOT NULL
    DROP TABLE Bills;
GO

-- Create the tables
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY,
    UserName NVARCHAR(50) NOT NULL,
    PasswordHash NVARCHAR(256) NOT NULL,
    Email NVARCHAR(100) NOT NULL
);

CREATE TABLE Hotels (
    HotelID INT PRIMARY KEY IDENTITY,
    HotelName NVARCHAR(100) NOT NULL,
    Address NVARCHAR(255) NOT NULL
);

CREATE TABLE Rooms (
    RoomID INT PRIMARY KEY IDENTITY,
    HotelID INT FOREIGN KEY REFERENCES Hotels(HotelID),
    RoomNumber NVARCHAR(10) NOT NULL,
    RoomType NVARCHAR(50) NOT NULL,
    IsAvailable BIT NOT NULL DEFAULT 1
);

INSERT INTO Rooms (RoomID, RoomType, Description)
VALUES
    (101, 'Standard', 'Cozy room with basic amenities'),
    (102, 'Deluxe', 'Spacious room with a view'),
    (103, 'Super Deluxe', 'Double-Bed room with a sea view'),
    (104, 'Suite', 'Elegant suite with separate living and sleeping areas'),
    (105, 'Family Room', 'Provides bunk beds for the little ones and a queen-size bed for adults'),
    (106, 'Business Class Room', 'Designed for business travelers and includes high-speed Wi-Fi, a coffee maker, and blackout curtains');


CREATE TABLE Reservations (
    ReservationID INT PRIMARY KEY IDENTITY,
    UserID INT FOREIGN KEY REFERENCES Users(UserID),
    RoomID INT FOREIGN KEY REFERENCES Rooms(RoomID),
    CheckInDate DATE NOT NULL,
    CheckOutDate DATE NOT NULL,
    ReservationDate DATE NOT NULL DEFAULT GETDATE()
);

CREATE TABLE Bills (
    BillID INT PRIMARY KEY IDENTITY,
    ReservationID INT FOREIGN KEY REFERENCES Reservations(ReservationID),
    Amount DECIMAL(10, 2) NOT NULL,
    BillingDate DATE NOT NULL DEFAULT GETDATE()
);
GO

-- Drop the procedure if it exists
IF OBJECT_ID('CheckRoomAvailability', 'P') IS NOT NULL
    DROP PROCEDURE CheckRoomAvailability;
GO

CREATE PROCEDURE CheckRoomAvailability
    @HotelID INT,
    @CheckInDate DATE,
    @CheckOutDate DATE
AS
BEGIN
    SELECT RoomID, RoomNumber, RoomType
    FROM Rooms
    WHERE HotelID = @HotelID
      AND IsAvailable = 1
      AND RoomID NOT IN (
          SELECT RoomID
          FROM Reservations
          WHERE CheckInDate < @CheckOutDate AND CheckOutDate > @CheckInDate
      );
END;
GO
-- Drop the procedure if it exists
IF OBJECT_ID('UserLogin', 'P') IS NOT NULL
    DROP PROCEDURE UserLogin;
GO

CREATE PROCEDURE UserLogin
    @UserName NVARCHAR(50),
    @Password NVARCHAR(256)
AS
BEGIN
    DECLARE @StoredPasswordHash NVARCHAR(256);

    SELECT @StoredPasswordHash = PasswordHash
    FROM Users
    WHERE UserName = @UserName;

    IF @StoredPasswordHash = HASHBYTES('SHA2_256', @Password)
    BEGIN
        SELECT 'Login Successful' AS Message;
    END
    ELSE
    BEGIN
        SELECT 'Invalid Username or Password' AS Message;
    END
END;
GO
-- Drop the procedure if it exists
IF OBJECT_ID('RegisterRoom', 'P') IS NOT NULL
    DROP PROCEDURE RegisterRoom;
GO

CREATE PROCEDURE RegisterRoom
    @HotelID INT,
    @RoomNumber NVARCHAR(10),
    @RoomType NVARCHAR(50)
AS
BEGIN
    INSERT INTO Rooms (HotelID, RoomNumber, RoomType, IsAvailable)
    VALUES (@HotelID, @RoomNumber, @RoomType, 1);
END;
GO
-- Drop the procedure if it exists
IF OBJECT_ID('RegisterHotel', 'P') IS NOT NULL
    DROP PROCEDURE RegisterHotel;
GO

CREATE PROCEDURE RegisterHotel
    @HotelName NVARCHAR(100),
    @Address NVARCHAR(255)
AS
BEGIN
    INSERT INTO Hotels (HotelName, Address)
    VALUES (@HotelName, @Address);
END;
GO
-- Drop the procedure if it exists
IF OBJECT_ID('GenerateBill', 'P') IS NOT NULL
    DROP PROCEDURE GenerateBill;
GO

CREATE PROCEDURE GenerateBill
    @ReservationID INT,
    @Amount DECIMAL(10, 2)
AS
BEGIN
    INSERT INTO Bills (ReservationID, Amount)
    VALUES (@ReservationID, @Amount);
END;
GO
-- Drop the procedure if it exists
IF OBJECT_ID('CheckIn', 'P') IS NOT NULL
    DROP PROCEDURE CheckIn;
GO

CREATE PROCEDURE CheckIn
    @ReservationID INT
AS
BEGIN
    UPDATE Rooms
    SET IsAvailable = 0
    WHERE RoomID = (SELECT RoomID FROM Reservations WHERE ReservationID = @ReservationID);
END;
GO
-- Drop the procedure if it exists
IF OBJECT_ID('CheckOut', 'P') IS NOT NULL
    DROP PROCEDURE CheckOut;
GO

CREATE PROCEDURE CheckOut
    @ReservationID INT
AS
BEGIN
    UPDATE Rooms
    SET IsAvailable = 1
    WHERE RoomID = (SELECT RoomID FROM Reservations WHERE ReservationID = @ReservationID);
END;
GO
EXEC CheckRoomAvailability @HotelID = 1, @CheckInDate = '2024-08-01', @CheckOutDate = '2024-08-05';