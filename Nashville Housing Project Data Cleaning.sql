use DB_Nashvill_Housing;

------------------------------------------------------------------------------------------------------------------

-- checking date format in column SaleDate

select SaleDate from [Nashville Housing Data for Data Cleaning1];

-------------------------------------------------------------------------------------------------------------------

-- filling null values in column  PropertyAddress

select a.ParcelID, a.PropertyAddress,b.ParcelID, b.PropertyAddress , isnull(a.PropertyAddress, b.PropertyAddress)
from [Nashville Housing Data for Data Cleaning1] a
join [Nashville Housing Data for Data Cleaning1] b												-- selecting values to be filled
on a.ParcelID = b.ParcelID and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null
;

update a																						-- filling null values to column PropertyAddress
set a.PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from [Nashville Housing Data for Data Cleaning1] a
join [Nashville Housing Data for Data Cleaning1] b 
on a.ParcelID = b.ParcelID and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null
;

------------------------------------------------------------------------------------------------------------------

-- Extracting out PropertyAddress into different columns(Address, City)

select SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,			-- (-1) to remove comma from the last
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City	-- (+1) to start after comma
from [Nashville Housing Data for Data Cleaning1]
;

Alter Table [Nashville Housing Data for Data Cleaning1]											 -- adding new column to the table
add PropertySplitAddress nvarchar(255);

update [Nashville Housing Data for Data Cleaning1]											   	 -- adding values to the new column
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

Alter Table [Nashville Housing Data for Data Cleaning1]
add PropertySplitCity nvarchar(255);

update [Nashville Housing Data for Data Cleaning1]
set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));

----------------------------------------------------------------------------------------------------------------------

-- Extracting out OwnerAddress into different columns(Address, City, State)

select PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) as Address,										-- checking the extraction of the column
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) as City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) as State
from [Nashville Housing Data for Data Cleaning1]

Alter Table [Nashville Housing Data for Data Cleaning1]												-- creating new column to the table
add OwnerSplitAddress nvarchar(255);

update [Nashville Housing Data for Data Cleaning1]													-- inserting values to the new column
set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3);

Alter Table [Nashville Housing Data for Data Cleaning1]
add OwnerSplitCity nvarchar(255);

update [Nashville Housing Data for Data Cleaning1]
set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2);

Alter Table [Nashville Housing Data for Data Cleaning1]
add OwnerSplitState nvarchar(255);

update [Nashville Housing Data for Data Cleaning1]
set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1);

select * from [Nashville Housing Data for Data Cleaning1];

------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in SoldAsVacant column

select case																					-- Making case when statement
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
end
from [Nashville Housing Data for Data Cleaning1];

update [Nashville Housing Data for Data Cleaning1]											-- updating column with case when statement
set SoldAsVacant = case 
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
end;


select distinct(SoldAsVacant), COUNT(SoldAsVacant)
from [Nashville Housing Data for Data Cleaning1]
group by SoldAsVacant;

-----------------------------------------------------------------------------------------------------------------------

-- Removing Duplicate Values


select distinct(UniqueID), COUNT(UniqueID) as count from [Nashville Housing Data for Data Cleaning1]
group by UniqueID
Having COUNT(UniqueID) > 1 ;															-- Checking duplicate rows 

with Row_num1 as																		-- deleting duplicate rows
(select *,
ROW_NUMBER()over(
	partition by
	ParcelID,
	PropertyAddress,
	SaleDate,
	SalePrice,
	LegalReference
	order by
	UniqueID
) R_Num
from [Nashville Housing Data for Data Cleaning1]
--order by R_Num desc
)
Delete from Row_num1
where R_Num > 1
;

-------------------------------------------------------------------------------------------------------------------------

-- deleting columns

alter table [Nashville Housing Data for Data Cleaning1]
drop column PropertyAddress, OwnerAddress, TaxDistrict ;

---------------------------------------------------------------------------------------------------------------------------
