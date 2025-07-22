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
    jenis_kartu VARCHAR(50) NOT NULL DEFAULT 'Silver',  -- NEW FIELD
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
    email_verified BOOLEAN DEFAULT FALSE NOT NULL,
    alamat_id BIGINT,
    wali_id BIGINT,  -- NULLABLE - wali sekarang optional
    
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
CREATE INDEX idx_customers_verified ON customers(email_verified);
CREATE INDEX idx_customers_jenis_kartu ON customers(jenis_kartu);  -- NEW INDEX

-- Create trigger untuk updated_at customers
CREATE TRIGGER trigger_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
