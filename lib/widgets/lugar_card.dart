import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class LugarCard extends StatelessWidget {

  final String nombre;
  final String direccion;
  final VoidCallback alSeleccionar;


  const LugarCard({
    super.key,
    required this.nombre,
    required this.direccion,
    required this.alSeleccionar,
  });


  @override
  Widget build(BuildContext context) {

    return InkWell(

      onTap: alSeleccionar,

      borderRadius: BorderRadius.circular(20),


      child: Container(

        margin: const EdgeInsets.only(
          bottom: 15,
        ),


        padding: const EdgeInsets.all(16),


        decoration: BoxDecoration(

          color: AppColors.blanco,

          borderRadius: BorderRadius.circular(20),


          boxShadow: const [

            BoxShadow(

              color: Colors.black12,

              blurRadius: 8,

              offset: Offset(0, 4),

            ),

          ],

        ),


        child: Row(

          children: [


            Container(

              padding: const EdgeInsets.all(12),


              decoration: BoxDecoration(

                color: AppColors.verde.withOpacity(0.15),

                shape: BoxShape.circle,

              ),


              child: Icon(

                Icons.location_on,

                color: AppColors.verde,

                size: 28,

              ),

            ),



            const SizedBox(width: 15),



            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,


                children: [


                  Text(

                    nombre,

                    style: const TextStyle(

                      fontWeight: FontWeight.bold,

                      fontSize: 16,

                    ),

                  ),



                  const SizedBox(height: 6),



                  Text(

                    direccion,

                    style: TextStyle(

                      color: AppColors.grisTexto,

                      fontSize: 14,

                    ),

                  ),


                ],

              ),

            ),



            Icon(

              Icons.arrow_forward_ios,

              size: 18,

              color: AppColors.grisTexto,

            ),


          ],

        ),

      ),

    );

  }

}