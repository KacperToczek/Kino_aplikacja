-- Projekt - Baza Danych "Kino fanów Jamesa Bonda"

-- utworzenie tabel z kluczami głównymi, kluczami obcymi i checkami

DROP TABLE gatunki CASCADE;
DROP TABLE kategorie_wiekowe CASCADE;
DROP TABLE filmy CASCADE;
DROP TABLE rodzaje CASCADE;
DROP TABLE bilety CASCADE;
DROP TABLE sale CASCADE;
DROP TABLE miejsca_w_salach CASCADE;
DROP TABLE jezyki CASCADE;
DROP TABLE repertuar CASCADE;
DROP TABLE klienci CASCADE;
DROP TABLE rezerwacje CASCADE;

CREATE TABLE gatunki(
	gatunek VARCHAR(30) PRIMARY KEY
);

CREATE TABLE kategorie_wiekowe(
	wiek VARCHAR(10) PRIMARY KEY
);

CREATE TABLE filmy(
	tytul VARCHAR(40) PRIMARY KEY,
	gatunek VARCHAR(30) REFERENCES gatunki(gatunek) ON UPDATE CASCADE,
	rezyser VARCHAR(30) NOT NULL,
	produkcja VARCHAR(30) NOT NULL,
	premiera DATE NOT NULL,
	czas_trwania_minuty INTEGER NOT NULL CHECK(czas_trwania_minuty > 0),
	kategoria_wiekowa VARCHAR(10) REFERENCES kategorie_wiekowe(wiek) ON UPDATE CASCADE
);

CREATE TABLE rodzaje(
	rodzaj VARCHAR(30) PRIMARY KEY
);

CREATE TABLE bilety(
	id_biletu SERIAL PRIMARY KEY,
	rodzaj VARCHAR(30) REFERENCES rodzaje(rodzaj) ON DELETE CASCADE ON UPDATE CASCADE,
	czy_ulgowy BOOLEAN NOT NULL DEFAULT(FALSE),
	cena DECIMAL(5,2) NOT NULL CHECK(cena>0),
	UNIQUE(rodzaj, czy_ulgowy)
);

CREATE TABLE sale(
	sala VARCHAR(10) PRIMARY KEY,
	ilosc_rzedow INTEGER NOT NULL CHECK(ilosc_rzedow>0),
	ilosc_kolumn INTEGER NOT NULL CHECK(ilosc_kolumn>0)
);

CREATE TABLE miejsca_w_salach(
	id_miejsca VARCHAR(30) PRIMARY KEY,
	sala VARCHAR(10) REFERENCES sale(sala) ON DELETE CASCADE ON UPDATE CASCADE,	
	miejsce INTEGER NOT NULL,
	rząd INTEGER NOT NULL
);

CREATE TABLE jezyki(
	id_jezyka SERIAL PRIMARY KEY,
	jezyk VARCHAR(10) NOT NULL,
	czy_napisy BOOLEAN NOT NULL DEFAULT(FALSE),
	czy_lektor BOOLEAN NOT NULL DEFAULT(FALSE),
	czy_dubbing BOOLEAN NOT NULL DEFAULT(FALSE),
	etykieta VARCHAR(30) DEFAULT(NULL),
	UNIQUE(jezyk, czy_napisy, czy_lektor, czy_dubbing)
);

CREATE TABLE repertuar(
	id_seansu SERIAL PRIMARY KEY,
	film VARCHAR(40) REFERENCES filmy(tytul) ON DELETE CASCADE ON UPDATE CASCADE,
	termin DATE NOT NULL,
	godzina_rozpoczecia TIME NOT NULL,
	jezyk INTEGER REFERENCES jezyki(id_jezyka) ON UPDATE CASCADE,
	rodzaj VARCHAR(30) REFERENCES rodzaje(rodzaj) ON UPDATE CASCADE,
	sala VARCHAR(10) REFERENCES sale(sala) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE klienci(
	imie VARCHAR(30) NOT NULL,
	nazwisko VARCHAR(30) NOT NULL,
	email VARCHAR(30) CHECK(email LIKE '%_@%_.__%') PRIMARY KEY
);

CREATE TABLE rezerwacje(
	id_rezerwacji SERIAL PRIMARY KEY,
	klient VARCHAR(30) REFERENCES klienci(email) ON DELETE CASCADE ON UPDATE CASCADE,
	seans INTEGER REFERENCES repertuar(id_seansu) ON DELETE CASCADE ON UPDATE CASCADE,
	miejsce VARCHAR(30) REFERENCES miejsca_w_salach(id_miejsca),
	bilet INTEGER REFERENCES bilety(id_biletu)
);



-- funkcje i triggery

--tworzenie miejsc podczas dodawania sal w kinie
CREATE OR REPLACE FUNCTION wstaw_miejsca_do_sali() RETURNS TRIGGER AS $$
DECLARE
	i INTEGER;
	j INTEGER;
BEGIN
	FOR i in 1 .. NEW.ilosc_rzedow LOOP
		FOR j in 1 .. NEW.ilosc_kolumn LOOP
			INSERT INTO miejsca_w_salach(id_miejsca, sala, miejsce, rzad) VALUES (NEW.sala || 'R' || i || 'C' || j, NEW.sala, j, i);			
		END LOOP;
	END LOOP;
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER wstaw_miejsca_do_sali_trigger ON sale CASCADE;
CREATE TRIGGER wstaw_miejsca_do_sali_trigger AFTER INSERT ON sale
FOR EACH ROW EXECUTE PROCEDURE wstaw_miejsca_do_sali();
	

--sprawdzanie czy filmy nie nachodzą na siebie w sali
CREATE OR REPLACE FUNCTION czy_dostepna_sala() RETURNS TRIGGER AS $$
DECLARE
	krotka RECORD;
	roznica TIME;
	czas_nowego INTEGER;
BEGIN
	FOR krotka IN SELECT * FROM repertuar INNER JOIN filmy ON (repertuar.film = filmy.tytul) WHERE repertuar.sala = NEW.sala AND repertuar.termin = NEW.termin LOOP
		IF krotka.godzina_rozpoczecia = NEW.godzina_rozpoczecia THEN
			RAISE EXCEPTION 'sala zajęta!';
		END IF;
		IF krotka.godzina_rozpoczecia < NEW.godzina_rozpoczecia THEN
			roznica = NEW.godzina_rozpoczecia - krotka.godzina_rozpoczecia;
			IF date_part('hour', roznica)*60 + date_part('minutes', roznica) <= krotka.czas_trwania_minuty THEN
				RAISE EXCEPTION 'sala zajęta!';
			END IF;
		END IF;
		IF krotka.godzina_rozpoczecia > NEW.godzina_rozpoczecia THEN
			roznica = krotka.godzina_rozpoczecia - NEW.godzina_rozpoczecia;
			SELECT czas_trwania_minuty INTO czas_nowego FROM filmy WHERE filmy.tytul = NEW.film;
			IF date_part('hour', roznica)*60 + date_part('minutes', roznica) <= czas_nowego THEN
				RAISE EXCEPTION 'sala zajęta!';
			END IF;
		END IF;
	END LOOP;
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER czy_dostepna_sala_trigger ON repertuar CASCADE;
CREATE TRIGGER czy_dostepna_sala_trigger BEFORE INSERT ON repertuar
FOR EACH ROW EXECUTE PROCEDURE czy_dostepna_sala();


--statusu miejsca w sali
CREATE OR REPLACE FUNCTION status_miejsca() RETURNS TRIGGER AS $$
BEGIN
	IF EXISTS (SELECT * FROM rezerwacje WHERE rezerwacje.miejsce = NEW.miejsce AND rezerwacje.seans = NEW.seans) THEN
		RAISE EXCEPTION 'to miejsce jest zajęte' ;
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER status_miejsca_trigger ON rezerwacje CASCADE;
CREATE TRIGGER status_miejsca_trigger BEFORE INSERT ON rezerwacje
FOR EACH ROW EXECUTE PROCEDURE status_miejsca();


-- etykiety wersji jezykowych
CREATE OR REPLACE FUNCTION etykiety_jezykow() RETURNS TRIGGER AS $$
BEGIN
	UPDATE jezyki SET etykieta = NEW.jezyk WHERE jezyki.id_jezyka = NEW.id_jezyka;
	IF NEW.czy_napisy THEN
			UPDATE jezyki SET etykieta = NEW.jezyk || '/napisy' WHERE jezyki.id_jezyka = NEW.id_jezyka;
	END IF;
	IF NEW.czy_lektor THEN
			UPDATE jezyki SET etykieta = NEW.jezyk || '/lektor' WHERE jezyki.id_jezyka = NEW.id_jezyka;
	END IF;
	IF NEW.czy_dubbing THEN
			UPDATE jezyki SET etykieta = NEW.jezyk || '/dubbing' WHERE jezyki.id_jezyka = NEW.id_jezyka;
	END IF;
	IF NEW.czy_napisy AND NEW.czy_lektor THEN
			UPDATE jezyki SET etykieta = NEW.jezyk || '/napisy/lektor' WHERE jezyki.id_jezyka = NEW.id_jezyka;
	END IF;
	IF NEW.czy_napisy AND NEW.czy_dubbing THEN
			UPDATE jezyki SET etykieta = NEW.jezyk || '/napisy/dubbing' WHERE jezyki.id_jezyka = NEW.id_jezyka;
	END IF;
	IF NEW.czy_dubbing AND NEW.czy_lektor THEN
			UPDATE jezyki SET etykieta = NEW.jezyk || '/dubbing/lektor' WHERE jezyki.id_jezyka = NEW.id_jezyka;
	END IF;
	IF NEW.czy_napisy AND NEW.czy_lektor AND NEW.czy_dubbing THEN
			UPDATE jezyki SET etykieta = NEW.jezyk || '/napisy/lektor/dubbing' WHERE jezyki.id_jezyka = NEW.id_jezyka;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER etykiety_jezykow_trigger ON jezyki CASCADE;
CREATE TRIGGER etykiety_jezykow_trigger AFTER INSERT ON jezyki
FOR EACH ROW EXECUTE PROCEDURE etykiety_jezykow(); 