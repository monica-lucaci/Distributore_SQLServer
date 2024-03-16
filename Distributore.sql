CREATE TABLE VendingMachine(
vendingMachineID INT PRIMARY KEY IDENTITY(1,1),
posizione VARCHAR(250) NOT NULL,
modello VARCHAR(250) NOT NULL
);

CREATE TABLE Product(
productID INT PRIMARY KEY IDENTITY(1,1),
nome VARCHAR(250) NOT NULL,
prezzo DECIMAL(10,2) NOT NULL,
quantita INT NOT NULL,
);

CREATE TABLE Transaction_(
transactionID INT PRIMARY KEY IDENTITY(1,1),
data_ora DATETIME  DEFAULT CURRENT_TIMESTAMP,
importo DECIMAL(10,2),
vendingMachineRif INT NOT NULL,
productRif INT NOT NULL,
FOREIGN KEY (vendingMachineRif) REFERENCES VendingMachine(vendingMachineID) ON DELETE CASCADE,
FOREIGN KEY (productRif) REFERENCES Product(productID) ON DELETE CASCADE
);

CREATE TABLE Supplier(
supplierID INT PRIMARY KEY IDENTITY(1,1),
nome VARCHAR(250) NOT NULL,
contatto VARCHAR(250) NOT NULL,
productRif INT NOT NULL,
FOREIGN KEY (productRif) REFERENCES Product(productID) ON DELETE CASCADE
);

CREATE TABLE Maintenance(
maintenanceID INT PRIMARY KEY IDENTITY(1,1),
dataIntervento DATETIME  DEFAULT CURRENT_TIMESTAMP,
descrizione TEXT NOT NULL,
vendingMachineRif INT NOT NULL,
FOREIGN KEY (vendingMachineRif) REFERENCES VendingMachine(vendingMachineID) ON DELETE CASCADE,
);

INSERT INTO VendingMachine (posizione, modello)
VALUES 
    ('Posizione 1', 'Modello A'),
    ('Posizione 2', 'Modello B'),
    ('Posizione 3', 'Modello C'),
    ('Posizione 4', 'Modello D'),
    ('Posizione 5', 'Modello E'),
    ('Posizione 6', 'Modello F');


INSERT INTO Product (nome, prezzo, quantita)
VALUES 
    ('Prodotto 1', 1.99, 10),
    ('Prodotto 2', 2.50, 15),
    ('Prodotto 3', 3.99, 8),
    ('Prodotto 4', 4.25, 20),
    ('Prodotto 5', 5.99, 12),
    ('Prodotto 6', 6.50, 18);


INSERT INTO Transaction_ (importo, vendingMachineRif, productRif)
VALUES 
    (10.50, 1, 1),
    (5.75, 2, 2),
    (7.99, 3, 3),
    (12.25, 4, 4),
    (8.99, 5, 5),
    (6.50, 6, 6);


INSERT INTO Supplier (nome, contatto, productRif)
VALUES 
    ('Fornitore A', 'Contatto A', 1),
    ('Fornitore B', 'Contatto B', 2),
    ('Fornitore C', 'Contatto C', 3),
    ('Fornitore D', 'Contatto D', 4),
    ('Fornitore E', 'Contatto E', 5),
    ('Fornitore F', 'Contatto F', 6);


INSERT INTO Maintenance (descrizione, vendingMachineRif)
VALUES 
    ('Manutenzione 1', 1),
    ('Manutenzione 2', 2),
    ('Manutenzione 3', 3),
    ('Manutenzione 4', 4),
    ('Manutenzione 5', 5),
    ('Manutenzione 6', 6);


/*1. Vista Prodotti per Distributore
Creare una vista ProductsByVendingMachine che mostri tutti i prodotti disponibili in ciascun
distributore, includendo l'ID e la posizione del distributore, il nome del prodotto, il prezzo e la
quantità disponibile.
*/

CREATE VIEW ProductsByVendingMachine AS
	SELECT v.vendingMachineID as ID, v.posizione as Position,p.nome AS ProductName,p.prezzo AS Price, p.quantita as Quantity
		FROM VendingMachine AS v
		JOIN Transaction_ AS t ON v.vendingMachineID = t.vendingMachineRif
		JOIN Product AS p ON t.productRif = p.productID;

SELECT * FROM ProductsByVendingMachine;


/*2. Vista Transazioni Recenti
Generare una vista RecentTransactions che elenchi le ultime transazioni effettuate, mostrando
l'ID della transazione, la data/ora, il distributore, il prodotto acquistato e l'importo della
transazione.
*/

CREATE VIEW RecentTransactions AS
		SELECT t.transactionID as IDTransazione, T.data_ora as Orario,v.posizione AS VendingMachinePosition, p.nome AS ProductName,t.importo
		FROM VendingMachine AS v
		JOIN Transaction_ AS t ON v.vendingMachineID = t.vendingMachineRif
		JOIN Product AS p ON t.productRif = p.productID;


SELECT * FROM RecentTransactions;

/*3. Vista Manutenzioni Programmate
Creare una vista ScheduledMaintenance che mostri tutti i distributori che hanno una
manutenzione programmata, includendo l'ID e la posizione del distributore e la data dell'ultima e
della prossima manutenzione.*/



CREATE VIEW ScheduledMaintenance AS
		SELECT v.vendingMachineID AS DistributoreID, v.posizione AS PosizioneDistributore, m.dataIntervento AS DataManutenzione
		FROM VendingMachine AS v
		JOIN Maintenance AS m ON v.vendingMachineID = m.vendingMachineRif

SELECT * FROM ScheduledMaintenance;


------STORED PROCEDURES------

/*1. Procedura di Ricarica Prodotto
Implementare una stored procedure RefillProduct che consenta di aggiungere scorte di un
prodotto specifico in un distributore, richiedendo l'ID del distributore, l'ID del prodotto e la
quantità da aggiungere.*/

DROP PROCEDURE IF EXISTS RefillProduct;
CREATE PROCEDURE RefillProduct 
		@productIDValue INT,
		@quantitaValue INT,
		@vendingMachineIDValue INT,
		@importoValue DECIMAL(10,2),
		@nomeValue VARCHAR(250)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			IF @quantitaValue <= 0
				THROW 50001, 'Quantita non concessa',1

		   IF EXISTS (SELECT 1 FROM Transaction_ WHERE vendingMachineRif = @vendingMachineIDValue AND productRif = @productIDValue)
            BEGIN
                UPDATE Product
                SET quantita = quantita + @quantitaValue
                WHERE productID = @productIDValue
            END
            ELSE
            BEGIN
				INSERT INTO Product(nome,prezzo,quantita) VALUES
				(@nomeValue,@importoValue,@quantitaValue)
                --INSERT INTO Transaction_ (data_ora, importo, vendingMachineRif, productRif)
                --VALUES (GETDATE(), @importoValue, @vendingMachineIDValue, @productIDValue)
            END

            PRINT 'PRODUCT QUANTITY UPDATED'

		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION

		PRINT 'ERRORE: ' + ERROR_MESSAGE()
	END CATCH
END;

EXEC RefillProduct
		@nomeValue = 'prodotto 7',
		@productIDValue = 7,
		@quantitaValue = 50,
		@vendingMachineIDValue = 5,
		@importoValue = 2.99;

SELECT * FROM Product;