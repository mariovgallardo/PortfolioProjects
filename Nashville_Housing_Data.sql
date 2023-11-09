/*

Cleaning Data with MySQL

*/

SELECT*
FROM nashville_housing_data

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


SELECT saleDateConverted, CONVERT(Date,SaleDate)
FROM nashville_housing_data


UPDATE nashville_housing_data
SET SaleDate = CONVERT(Date,SaleDate)

--------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

SELECT*
FROM nashville_housing_data
-- Where PropertyAddress is null
ORDER BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress,b.PropertyAddress)
FROM nashville_housing_data a 
	JOIN nashville_housing_data b  
    ON a.ParcelID = b.ParcelID  
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null


UPDATE nashville_housing_data AS a
JOIN nashville_housing_data AS b 
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL

-- Breaking out Address Into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM nashville_housing_data
-- Where PropertyAddress is null
-- order by ParcelID

SELECT PropertyAddress,
substring_index(substring_index(PropertyAddress, ',', 1), ',', -1) AS Address,
substring_index(substring_index(PropertyAddress, ',', 2), ',', -1) AS City,
substring_index(substring_index(PropertyAddress, ',', 3), ',' , -1) AS State
FROM nashville_housing_data


ALTER TABLE nashville_housing_data
ADD PropertySplitAddress CHAR(255);

UPDATE nashville_housing_data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1)


ALTER TABLE nashville_housing_data
ADD PropertySplitCity CHAR(255);

UPDATE nashville_housing_data
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1)

-- Not adding a column for State since this is all data from TN

--------------------------------------------------------------------------------------------------------------------------

-- Splitting up the OwnerAddress column in a similar manner as above

SELECT OwnerAddress
FROM nashville_housing_data

SELECT OwnerAddress,
	substring_index(substring_index(OwnerAddress, ',', 1), ',', -1) AS Address,
	substring_index(substring_index(OwnerAddress, ',', 2), ',', -1) AS City,
	substring_index(substring_index(OwnerAddress, ',', 3), ',' , -1) AS State
FROM nashville_housing_data


ALTER TABLE nashville_housing_data
ADD OwnerSplitAddress CHAR(255);

UPDATE nashville_housing_data
SET OwnerSplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1)


ALTER TABLE nashville_housing_data
ADD OwnerSplitCity CHAR(255);

UPDATE nashville_housing_data
SET OwnerSplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1)

SELECT*
FROM nashville_housing_data

--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field 

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashville_housing_data
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = "Y" THEN "Yes"
		 WHEN SoldAsVacant = "N" THEN "No"
		 ELSE SoldAsVacant
         END
FROM nashville_housing_data

UPDATE nashville_housing_data
SET SoldAsVacant = CASE WHEN SoldAsVacant = "Y" THEN "Yes"
		 WHEN SoldAsVacant = "N" THEN "No"
		 ELSE SoldAsVacant
		 ELSE SoldAsVacant
         END

--------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates Using a CTE

WITH rownumcte AS (
SELECT UniqueID ,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
	PropertyAddress, 
	SalePrice,
    SaleDate,
    LegalReference  
    ORDER BY UniqueID) AS rownum
FROM nashville_housing_data)
DELETE hd
FROM nashville_housing_data hd INNER JOIN rownumcte r ON hd.UniqueID = r.UniqueID
WHERE rownum>1;

--------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns 

SELECT*
FROM nashville_housing_data


ALTER TABLE nashville_housing_data
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress; 

--------------------------------------------------------------------------------------------------------------------------