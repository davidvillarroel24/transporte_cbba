import 'package:flutter/material.dart';

import 'favoritos_screen.dart';
import 'inicio_screen.dart';
import 'mapa_screen.dart';
import 'perfil_screen.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}


class _MainNavigationState extends State<MainNavigation> {

  int paginaActual = 0;


  final List<Widget> pantallas = [

    const InicioScreen(),

    const MapaScreen(),

    const FavoritosScreen(),

    const PerfilScreen(),

  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: pantallas[paginaActual],


      bottomNavigationBar: NavigationBar(

        selectedIndex: paginaActual,


        onDestinationSelected: (index) {

          setState(() {

            paginaActual = index;

          });

        },


        destinations: const [

          NavigationDestination(
            icon: Icon(Icons.home),
            label: "Inicio",
          ),


          NavigationDestination(
            icon: Icon(Icons.map),
            label: "Mapa",
          ),


          NavigationDestination(
            icon: Icon(Icons.star),
            label: "Favoritos",
          ),


          NavigationDestination(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),

        ],

      ),

    );
  }
}