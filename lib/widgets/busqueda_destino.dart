import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class BusquedaDestino extends StatelessWidget {

  final VoidCallback alBuscar;


  const BusquedaDestino({
    super.key,
    required this.alBuscar,
  });


  @override
  Widget build(BuildContext context) {

    return Column(

      children: [


        Container(

          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 6,
          ),


          decoration: BoxDecoration(

            color: AppColors.blanco,

            borderRadius: BorderRadius.circular(20),


            boxShadow: const [

              BoxShadow(

                color: Colors.black12,

                blurRadius: 10,

                offset: Offset(0, 4),

              ),

            ],

          ),


          child: const TextField(

            decoration: InputDecoration(

              icon: Icon(
                Icons.search,
              ),


              hintText: "¿A dónde quieres ir?",


              border: InputBorder.none,


            ),

          ),

        ),



        const SizedBox(height: 15),



        SizedBox(

          width: double.infinity,


          child: ElevatedButton.icon(

            onPressed: alBuscar,


            icon: const Icon(
              Icons.route,
            ),


            label: const Text(
              "Buscar ruta",
            ),


          ),

        ),


      ],

    );

  }

}