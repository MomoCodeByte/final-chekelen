-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 04, 2025 at 06:43 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `chekerendb`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `test_user_deletion` ()   BEGIN
  DECLARE test_id INT;
  
  
  SELECT MAX(user_id)+1 INTO test_id FROM users;
  
  START TRANSACTION;
  
  
  INSERT INTO users (user_id, username, email) VALUES 
  (test_id, CONCAT('test_user_', test_id), CONCAT('test_', test_id, '@example.com'));
  
  
  INSERT INTO reports (admin_id, report_type, content) VALUES 
  (test_id, 'test_type', 'Test report content');
  
  
  SELECT COUNT(*) AS reports_before FROM reports WHERE admin_id = test_id;
  
  
  DELETE FROM users WHERE user_id = test_id;
  
  
  SELECT COUNT(*) AS reports_after FROM reports WHERE admin_id = test_id;
  
  ROLLBACK;
  SELECT 'Test completed successfully' AS result;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `cart_items`
--

CREATE TABLE `cart_items` (
  `cart_item_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `crop_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cart_items`
--

INSERT INTO `cart_items` (`cart_item_id`, `user_id`, `crop_id`, `quantity`, `added_at`) VALUES
(13, 5, 16, 2, '2025-05-04 04:15:15');

-- --------------------------------------------------------

--
-- Table structure for table `chat`
--

CREATE TABLE `chat` (
  `chat_id` int(11) NOT NULL,
  `sender_id` int(11) DEFAULT NULL,
  `receiver_id` int(11) DEFAULT NULL,
  `message` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `crops`
--

CREATE TABLE `crops` (
  `crop_id` int(11) NOT NULL,
  `farmer_id` int(11) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `categories` varchar(100) DEFAULT 'general',
  `price` decimal(10,2) NOT NULL,
  `organic` tinyint(1) DEFAULT 0,
  `fresh` tinyint(1) DEFAULT 0,
  `image_path` varchar(255) DEFAULT NULL,
  `is_available` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `crops`
--

INSERT INTO `crops` (`crop_id`, `farmer_id`, `name`, `categories`, `price`, `organic`, `fresh`, `image_path`, `is_available`) VALUES
(3, 2, 'maharage', 'Legumes', 2000.00, 1, 0, NULL, 1),
(4, 2, 'Rice', 'Cereals', 1500.00, 0, 1, NULL, 1),
(16, 2, 'mahindi', 'Cereals', 450000.00, 0, 1, NULL, 1),
(17, 2, 'pilipili hoho', 'Root Crops', 20000.00, 0, 1, NULL, 1),
(18, 2, 'mapera', 'fluite', 40000.00, 1, 0, NULL, 1),
(19, 2, 'karafuu', 'Cash Crops', 50000.00, 0, 1, NULL, 1),
(20, 2, 'vitunguu', 'Cash Crops', 6000.00, 1, 0, NULL, 1),
(21, 2, 'matikiti maji', 'Fruits', 40000.00, 1, 1, NULL, 1),
(22, 2, 'nyanya', 'Vegetables', 45000.00, 1, 1, NULL, 1),
(23, 2, 'maembe', 'Fruits', 200000.00, 1, 0, NULL, 1),
(24, 2, 'ndizi', 'Fruits', 30000.00, 0, 1, NULL, 1),
(25, 2, 'mapara chichi', 'Fruits', 3000.00, 1, 1, NULL, 1);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` int(11) NOT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `order_status` enum('pending','processed','shipped','delivered','cancelled') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`order_id`, `customer_id`, `total_price`, `order_status`, `created_at`) VALUES
(1, 3, 350.00, '', '2025-04-15 20:54:12'),
(3, 5, 700.00, 'pending', '2025-05-02 08:21:59'),
(7, 2, 3000.00, '', '2025-04-28 12:51:32'),
(9, 2, 70000.00, 'processed', '2025-04-28 12:52:45'),
(11, 2, 30000.00, 'pending', '2025-05-01 21:27:19'),
(13, 5, 6000.00, 'delivered', '2025-05-03 07:43:30'),
(14, 5, 6000.00, 'pending', '2025-05-03 07:54:28'),
(15, 5, 4000.00, 'processed', '2025-05-03 11:30:10'),
(16, 5, 10500.00, 'pending', '2025-05-03 11:55:17'),
(17, 5, 4503000.00, 'pending', '2025-05-03 19:29:59'),
(18, 5, 6000.00, 'pending', '2025-05-03 19:40:07'),
(19, 5, 6000.00, 'pending', '2025-05-03 19:41:20'),
(20, 5, 200000.00, 'pending', '2025-05-03 20:01:17'),
(21, 5, 12000.00, 'pending', '2025-05-04 03:54:06');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `order_item_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `crop_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`order_item_id`, `order_id`, `crop_id`, `quantity`, `unit_price`) VALUES
(3, 13, 16, 4, 1000.00),
(4, 13, 4, 2, 1000.00),
(5, 14, 16, 4, 1000.00),
(6, 14, 4, 2, 1000.00),
(7, 15, 16, 2, 1000.00),
(8, 15, 4, 2, 1000.00),
(9, 16, 16, 2, 4500.00),
(10, 16, 18, 1, 1500.00),
(11, 17, 16, 2, 450000.00),
(12, 17, 16, 2, 450000.00),
(13, 17, 16, 2, 450000.00),
(14, 17, 16, 2, 450000.00),
(15, 17, 16, 2, 450000.00),
(16, 17, 4, 2, 1500.00),
(17, 18, 4, 1, 1500.00),
(18, 18, 4, 3, 1500.00),
(19, 19, 3, 3, 2000.00),
(20, 20, 19, 4, 50000.00),
(21, 21, 3, 3, 2000.00),
(22, 21, 25, 2, 3000.00);

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `report_id` int(11) NOT NULL,
  `admin_id` int(11) DEFAULT NULL,
  `report_type` varchar(255) NOT NULL,
  `content` text DEFAULT NULL,
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reports`
--

INSERT INTO `reports` (`report_id`, `admin_id`, `report_type`, `content`, `generated_at`) VALUES
(5, 1, 'password issue', 'customer => mofat\nemail => mofatgibson@gmail.com', '2025-04-23 12:17:15'),
(9, 1, 'this to do', 'user update by role,\ndisplay crops,\nmanage an order\n', '2025-04-25 11:47:49');

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

CREATE TABLE `settings` (
  `setting_id` int(11) NOT NULL,
  `admin_id` int(11) DEFAULT NULL,
  `setting_name` varchar(255) NOT NULL,
  `setting_value` varchar(255) NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `settings`
--

INSERT INTO `settings` (`setting_id`, `admin_id`, `setting_name`, `setting_value`, `updated_at`) VALUES
(2, 1, 'Maintenance Mode', 'Off', '2025-04-15 22:54:50'),
(3, 1, 'Contact Email', 'admin@myawesomesite.com', '2025-04-15 22:54:50');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `transaction_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `transaction_type` enum('purchase','refund','commission') NOT NULL,
  `status` enum('pending','completed','failed') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`transaction_id`, `user_id`, `amount`, `transaction_type`, `status`, `created_at`) VALUES
(1, 2, 200000.00, 'purchase', 'completed', '2025-04-25 11:48:42'),
(2, 2, 70000.00, 'purchase', 'pending', '2025-05-01 21:28:46');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(255) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('customer','farmer','admin','guest','ai') NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password`, `role`, `email`, `phone`, `created_at`) VALUES
(1, 'mofat gibson', '$2b$10$coWxmLm2j6tRWk21OU9PteEVQ8EID0WGIGsx9KDHCBslF0mqibDUy', 'admin', 'jude@gmail.com', '0716525951', '2025-04-11 21:33:29'),
(2, 'momo g', '$2b$10$g/EbrDNYhqYRFJI9b/KM8u5ZDBxQDQioiP8aPcrpP4GBYYvc6t9hC', 'farmer', 'momo@gmail.com', '0616525951', '2025-04-11 21:34:41'),
(5, 'miko', '$2b$10$jswusq6GUPTw/qlRa2y5bOFQLVQ7RYCrJNVx.nCPOCgc0sy9XyFAG', 'customer', 'miko@gmail.com', '0716534567', '2025-04-17 09:41:44'),
(8, 'mofat', '$2b$10$WB6VRWgFVKqR0gd4rvsTO.jGE85rFOXrEnhOcB42Pt5E6OmMZY9RW', 'farmer', 'mofat@gmail.com', '076346789', '2025-04-17 14:29:27'),
(11, 'judith', '$2b$10$UaxJhgsMIFxvibqmsOqSkeUr9cVsPfs4kZ1I3moCAdbtIeC6pHfxa', 'customer', 'judjuy@gmail.com', '078837776', '2025-04-17 16:57:05'),
(12, 'sos', '$2b$10$2I.7I0HD4SkYYY5ka1CsKuz6uB2v1VXmZO6wwnVjYuikWD4iEptF6', 'customer', 'sos@gmail.com', '0716525492', '2025-04-19 12:54:07'),
(1000001, 'Babu Shebuu', '$2b$10$n8a9dwyRH/JVYye8Du55XuO/yT.k6dWZYlUfaEwMmZ3LS4/4Iq.3m', 'farmer', 'babu@gmail.com', '07165255951', '2025-04-28 14:52:35'),
(1000004, 'ai_bot', 'not_applicable', 'ai', 'ai_bot@system.com', NULL, '2025-05-01 13:38:21'),
(1000005, 'guest_default', 'not_applicable', 'guest', 'guest@system.com', NULL, '2025-05-01 13:38:21');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`cart_item_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `crop_id` (`crop_id`);

--
-- Indexes for table `chat`
--
ALTER TABLE `chat`
  ADD PRIMARY KEY (`chat_id`),
  ADD KEY `sender_id` (`sender_id`),
  ADD KEY `receiver_id` (`receiver_id`);

--
-- Indexes for table `crops`
--
ALTER TABLE `crops`
  ADD PRIMARY KEY (`crop_id`),
  ADD KEY `fk_crops_farmer` (`farmer_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `customer_id` (`customer_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`order_item_id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `crop_id` (`crop_id`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`report_id`),
  ADD KEY `fk_report_admin` (`admin_id`);

--
-- Indexes for table `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`setting_id`),
  ADD KEY `fk_settings_admin` (`admin_id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `cart_items`
--
ALTER TABLE `cart_items`
  MODIFY `cart_item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `chat`
--
ALTER TABLE `chat`
  MODIFY `chat_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `crops`
--
ALTER TABLE `crops`
  MODIFY `crop_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `report_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `settings`
--
ALTER TABLE `settings`
  MODIFY `setting_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1000006;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`crop_id`) REFERENCES `crops` (`crop_id`);

--
-- Constraints for table `chat`
--
ALTER TABLE `chat`
  ADD CONSTRAINT `chat_ibfk_1` FOREIGN KEY (`sender_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `chat_ibfk_2` FOREIGN KEY (`receiver_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `crops`
--
ALTER TABLE `crops`
  ADD CONSTRAINT `fk_crops_farmer` FOREIGN KEY (`farmer_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`),
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`crop_id`) REFERENCES `crops` (`crop_id`);

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `fk_report_admin` FOREIGN KEY (`admin_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `settings`
--
ALTER TABLE `settings`
  ADD CONSTRAINT `fk_settings_admin` FOREIGN KEY (`admin_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `fk_transactions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
