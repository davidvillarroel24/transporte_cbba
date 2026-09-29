import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class DestinoCard extends StatelessWidget {

  final String nombre;
  final VoidCallback alSeleccionar;


  const DestinoCard({

    super.key,

    required this.nombre,

    required this.alSeleccionar,

  });


  @override
  Widget build(BuildContext context) {

    return InkWell(

      onTap: alSeleccionar,

      borderRadius: BorderRadius.circular(15),


      child: Container(

        margin: const EdgeInsets.only(
          bottom: 12,
        ),


        padding: const EdgeInsets.all(15),


        decoration: BoxDecoration(

          color: AppColors.blanco,

          borderRadius: BorderRadius.circular(15),


          boxShadow: const [

            BoxShadow(

              color: Colors.black12,

              blurRadius: 6,

              offset: Offset(0, 3),

            ),

          ],

        ),


        child: Row(

          children: [


            Container(

              padding: const EdgeInsets.all(10),


              decoration: BoxDecoration(

                color: AppColors.verde.withOpacity(0.15),

                shape: BoxShape.circle,

              ),


              child: const Icon(

                Icons.location_on,

                color: Colors.red,

              ),

            ),



            const SizedBox(width: 15),



            Expanded(

              child: Text(

                nombre,

                style: const TextStyle(

                  fontSize: 16,

                  fontWeight: FontWeight.bold,

                ),

              ),

            ),



            const Icon(

              Icons.arrow_forward_ios,

              size: 16,

            ),


          ],

        ),

      ),

    );

  }

}