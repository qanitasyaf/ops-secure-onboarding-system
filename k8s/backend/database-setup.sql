-- ===== UPDATED DATABASE SETUP SCRIPT =====
-- File: database_setup_for_login_attempts.sql
-- Jalankan dengan: psql postgres -f database/database-setup.sql

-- 1. Pastikan fungsi update_updated_at_column ada (jika belum ada di database postgres)
-- Jika fungsi ini sudah ada di instance PostgreSQL Anda, bagian ini bisa dilewati.
-- Anda bisa menjalankan ini sekali saja di database postgres default atau di setiap database baru.

-- 2. Create Database untuk Customer Registration
DROP DATABASE IF EXISTS customer_registration;
-- CREATE DATABASE customer_registration WITH OWNER = postgres;
CREATE DATABASE customer_registration;

-- 3. Setup Customer Registration Database
\c customer_registration;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Setup Customer Registration Database
\c customer_registration;

-- Drop existing tables
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS alamat CASCADE;
DROP TABLE IF EXISTS wali CASCADE;

-- Create Alamat table
CREATE TABLE alamat (
    id BIGSERIAL PRIMARY KEY,
    nama_alamat VARCHAR(255) NOT NULL,
    provinsi VARCHAR(100) NOT NULL,
    kota VARCHAR(100) NOT NULL,
    kecamatan VARCHAR(100) NOT NULL,
    kelurahan VARCHAR(100) NOT NULL,
    kode_pos VARCHAR(10) NOT NULL
);

-- Create Wali table (OPTIONAL - bisa null)
CREATE TABLE wali (
    id BIGSERIAL PRIMARY KEY,
    jenis_wali VARCHAR(50) NOT NULL,
    nama_lengkap_wali VARCHAR(255) NOT NULL,
    pekerjaan_wali VARCHAR(100) NOT NULL,
    alamat_wali VARCHAR(500) NOT NULL,
    nomor_telepon_wali VARCHAR(15) NOT NULL
);

-- Create Customers table dengan field jenisKartu dan wali optional
CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    nama_lengkap VARCHAR(255) NOT NULL,
    nik VARCHAR(16) NOT NULL UNIQUE,
    nama_ibu_kandung VARCHAR(255) NOT NULL,
    nomor_telepon VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    tipe_akun VARCHAR(100) NOT NULL,
    jenis_kartu VARCHAR(50) NOT NULL DEFAULT 'Silver',
    nomor_kartu_debit_virtual VARCHAR(19) UNIQUE,
    tempat_lahir VARCHAR(100) NOT NULL,
    tanggal_lahir DATE NOT NULL,
    jenis_kelamin VARCHAR(20) NOT NULL,
    agama VARCHAR(50) NOT NULL,
    status_pernikahan VARCHAR(50) NOT NULL,
    pekerjaan VARCHAR(100) NOT NULL,
    sumber_penghasilan VARCHAR(100) NOT NULL,
    rentang_gaji VARCHAR(50) NOT NULL,
    tujuan_pembuatan_rekening VARCHAR(255) NOT NULL,
    kode_rekening INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- email_verified BOOLEAN DEFAULT FALSE NOT NULL,
    
    -- START MODIFIKASI UNTUK FITUR MAKSIMUM LOGIN ATTEMPTS
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    account_locked_until TIMESTAMP, -- NULLABLE: hanya diisi jika akun terkunci
    -- END MODIFIKASI
    
    alamat_id BIGINT,
    wali_id BIGINT,
    
    -- Foreign Keys
    CONSTRAINT fk_customer_alamat FOREIGN KEY (alamat_id) REFERENCES alamat(id),
    CONSTRAINT fk_customer_wali FOREIGN KEY (wali_id) REFERENCES wali(id),
    
    -- Check constraints
    CONSTRAINT chk_jenis_kelamin CHECK (jenis_kelamin IN ('Laki-laki', 'Perempuan')),
    CONSTRAINT chk_jenis_kartu CHECK (jenis_kartu IN ('Silver', 'Gold', 'Platinum', 'Batik Air', 'GPN'))
);

-- Create indexes
CREATE INDEX idx_customers_email ON customers(LOWER(email));
CREATE INDEX idx_customers_phone ON customers(nomor_telepon);
CREATE INDEX idx_customers_nik ON customers(nik);
-- CREATE INDEX idx_customers_verified ON customers(email_verified);
CREATE INDEX idx_customers_jenis_kartu ON customers(jenis_kartu);
CREATE INDEX idx_customers_kartu_debit ON customers(nomor_kartu_debit_virtual);

-- Create trigger untuk updated_at customers
-- Pastikan fungsi update_updated_at_column sudah dibuat sebelumnya
CREATE TRIGGER trigger_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verify setup
SELECT 'Database setup completed successfully!' as status;
\c customer_registration;
SELECT 'Customer Registration setup completed!' as status;