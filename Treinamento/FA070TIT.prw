
#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'




//--------------------------------------------------
	/*/{Protheus.doc} FA070TIT
	Confirma baixa de titulo a receber  

	@author Thierry Pereira
	@since 23/12/2022

	@return
	/*/
//--------------------------------------------------

User Function FA070TIT ()

Local aArea  := GetArea()
Local lRet   := .T.

If MsgYesNo( 'Confirma a baixa do titulo?', 'Baixa de titulo a receber' )
    Alert(" Titulo baixado ")
Else
    lRet := .F.
Endif

RestArea(aArea)

Return lRet
