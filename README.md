# Parkuj
Nawigacja iPhone+CarPlay do parkingu

Ta aplikacja jest dostępna wyłacznie dla Polski.

To miał być mój test nowego frameworka SwiftUI, w praktyce okazało się że nadal (2022) nie jest on wystarczająco dojrzały do budowy UI dla produkcyjnej wersji aplikacji. Ze wzgledu na frustrację i marnowanie czasu na rozwiązywanie rożnych problemów (animacje vs brakujące funkcje gestów widoków), porzuciłem ten projekt.

Co działa: aplikacja mobilna, pokazuje mapę, parkingi w okolicy użytkownika. Dodatkowo działa także aplikacja CarPlay i mapa wyświetlana w samochodzie. To są odrębne aplikacje (CarPlay wymaga customowo nadawanego permission).

W zamierzeniu aplikacja miała wyszukiwać w trakcie jazdy parkingi w pobliżu i nawigować w ich kierunku.

Zbudowałem bazę takich miejsc automatycznie, korzystając głównie z OSM, korekty przez Google Maps i TomTom.

