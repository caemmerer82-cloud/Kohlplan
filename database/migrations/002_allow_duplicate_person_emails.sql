-- Create the replacement (non-unique) index first, so the foreign key on
-- tenant_id always has a supporting index available - otherwise dropping the
-- old unique index in the next step fails with "needed in a foreign key
-- constraint" because MySQL was using it to satisfy the FK.
ALTER TABLE persons ADD INDEX idx_tenant_email (tenant_id, email);

-- Now drop whichever unique index currently covers (tenant_id, email),
-- regardless of its auto-generated name.
SET @idx_name = (
  SELECT INDEX_NAME FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'persons'
    AND NON_UNIQUE = 0
    AND INDEX_NAME != 'PRIMARY'
    AND INDEX_NAME != 'idx_tenant_email'
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
