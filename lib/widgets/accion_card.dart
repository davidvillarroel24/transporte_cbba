import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class AccionCard extends StatelessWidget {

  final IconData icono;
  final String titulo;
  final VoidCallback alPresionar;


  const AccionCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.alPresionar,
  });


  @override
  Widget build(BuildContext context) {

    return InkWell(

      onTap: alPresionar,

      borderRadius: BorderRadius.circular(20),


      child: Container(

        width: 160,

        height: 140,


        padding: const EdgeInsets.all(15),


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


        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,


          children: [


            Container(

              padding: const EdgeInsets.all(12),


              decoration: BoxDecoration(

                color: AppColors.verde.withOpacity(0.15),

                shape: BoxShape.circle,

              ),


              child: Icon(

                icono,

                size: 35,

                color: AppColors.verde,

              ),

            ),



            const SizedBox(height: 12),



            Text(

              titulo,

              textAlign: TextAlign.center,


              style: const TextStyle(

                fontWeight: FontWeight.bold,

                fontSize: 15,

              ),

            ),


          ],

        ),

      ),

    );

  }

}