-- inserty do kina

INSERT INTO gatunki VALUES ('sensacyjny');
INSERT INTO gatunki VALUES ('komedia');
INSERT INTO gatunki VALUES ('horror');
INSERT INTO gatunki VALUES ('obyczajowy');
INSERT INTO gatunki VALUES ('thriller');


INSERT INTO kategorie_wiekowe VALUES ('6+');  
INSERT INTO kategorie_wiekowe VALUES ('13+');
INSERT INTO kategorie_wiekowe VALUES ('16+');


INSERT INTO filmy(tytul, gatunek, rezyser, produkcja, premiera, czas_trwania_minuty, kategoria_wiekowa) VALUES 
('Doktor No', 'sensacyjny', 'Terence Young', 'Wielka Brytania', '10.05.1962', 109, '13+'),
('Pozdrowienia z Rosji', 'sensacyjny', 'Terence Young', 'Wielka Brytania / USA', '10.10.1963', 111, '13+'),
('Goldfinger', 'sensacyjny', 'Guy Hamilton', 'USA / Wielka Brytania', '09.17.1964', 110, '13+'),
('Operacja Piorun', 'sensacyjny', 'Terence Young', 'USA / Wielka Brytania', '12.21.1965', 130, '13+'),
('Żyje się tylko dwa razy', 'sensacyjny', 'Lewis Gilbert', 'Wielka Brytania / USA', '06.12.1967', 117, '13+'),
('W tajnej służbie Jej Królewskiej Mości', 'sensacyjny', 'Peter R. Hunt', 'USA / Wielka Brytania', '12.18.1969', 142, '13+'),
('Diamenty są wieczne', 'sensacyjny', 'Guy Hamilton', 'Wielka Brytania / USA', '12.17.1971', 120, '13+'),
('Żyj i pozwól umrzeć', 'sensacyjny', 'Guy Hamilton', 'Wielka Brytania', '06.27.1973', 121, '13+'),
('Człowiek ze złotym pistoletem', 'sensacyjny', 'Guy Hamilton', 'Wielka Brytania', '12.18.1974', 125, '13+'),
('Szpieg, który mnie kochał', 'sensacyjny', 'Lewis Gilbert', 'Wielka Brytania', '07.07.1977', 125, '13+'),
('Moonraker', 'sensacyjny', 'Lewis Gilbert', 'Wielka Brytania', '06.26.1979', 126, '13+'),
('Tylko dla twoich oczu', 'sensacyjny', 'John Glen', 'Wielka Brytania', '06.24.1981', 127, '13+'),
('Ośmiorniczka', 'sensacyjny', 'John Glen', 'Wielka Brytania', '06.06.1983', 131, '13+'),
('Zabójczy widok', 'sensacyjny', 'John Glen', 'Wielka Brytania / USA', '05.24.1985', 131, '13+'),
('W obliczu śmierci', 'sensacyjny', 'John Glen', 'USA / Wielka Brytania', '06.29.1987', 130, '13+'),
('Licencja na zabijanie', 'sensacyjny', 'John Glen', 'USA / Wielka Brytania', '06.13.1989', 133, '13+'),
('GoldenEye', 'sensacyjny', 'Martin Campbell', 'USA / Wielka Brytania', '11.13.1995', 130, '13+'),
('Jutro nie umiera nigdy', 'sensacyjny', 'Roger Spottiswoode', 'USA / Wielka Brytania', '12.12.1997', 119, '13+'),
('Świat to za mało', 'sensacyjny', 'Michael Apted', 'USA / Wielka Brytania', '11.08.1999', 128, '13+'),
('Śmierć nadejdzie jutro', 'sensacyjny', 'Lee Tamahori', 'Wielka Brytania / USA', '11.18.2002', 133, '13+'),
('Casino Royale', 'sensacyjny', 'Martin Campbell', 'Wielka Brytania', '11.14.2006', 144, '13+'),
('007 Quantum of Solace', 'sensacyjny', 'Marc Forster', 'Wielka Brytania / USA', '10.31.2008', 106, '13+'),
('Skyfall', 'sensacyjny', 'Sam Mendes', 'Wielka Brytania / USA', '10.23.2012', 143, '13+'),
('Spectre', 'sensacyjny', 'Sam Mendes', 'USA / Wielka Brytania', '10.26.2015', 148, '13+'),
('Nie czas umierać', 'sensacyjny', 'Cary Joji Fukunaga', 'USA / Wielka Brytania', '10.08.2021', 3, '13+');



INSERT INTO rodzaje VALUES ('2D'); 
INSERT INTO rodzaje VALUES ('3D');


INSERT INTO bilety(rodzaj, czy_ulgowy, cena) VALUES
('2D', TRUE, 20),
('2D', FALSE, 25), 
('3D', TRUE, 25), 
('3D', FALSE, 30);


INSERT INTO sale(sala, ilosc_rzedow, ilosc_kolumn) VALUES ('s1',5,5);
INSERT INTO sale(sala, ilosc_rzedow, ilosc_kolumn) VALUES ('s2',5,5);
INSERT INTO sale(sala, ilosc_rzedow, ilosc_kolumn) VALUES ('s3',5,5);



INSERT INTO jezyki(jezyk, czy_napisy, czy_lektor, czy_dubbing) VALUES ('polski', FALSE, TRUE, FALSE);
INSERT INTO jezyki(jezyk, czy_napisy, czy_lektor, czy_dubbing) VALUES ('polski', TRUE, FALSE, FALSE);



INSERT INTO klienci(imie, nazwisko, email) VALUES ('Kacper', 'Toczek', 'kt@gmail.com'); 
