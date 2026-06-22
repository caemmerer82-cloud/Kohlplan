-- Drop whichever unique index currently covers (tenant_id, email), regardless
-- of its auto-generated name, then replace it with a plain (non-unique) index
-- so multiple persons can share the same email address.
SET @idx_name = (
  SELECT INDEX_NAME FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'persons'
    AND NON_UNIQUE = 0
    AND INDEX_NAME != 'PRIMARY'
  GROUP BY INDEX_NAME
  HAVING GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) = 'tenant_id,email'
  LIMIT 1
);

SET @drop_sql = IF(@idx_name IS NOT NULL,
  CONCAT('ALTER TABLE persons DROP INDEX `', @idx_name, '`'),
  'SELECT 1'
);

PREPARE stmt FROM @drop_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE persons ADD INDEX idx_tenant_email (tenant_id, email);
