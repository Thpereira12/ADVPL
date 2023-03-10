
#Include 'TOTVS.ch'
#Include 'FWMVCDef.ch'

//--------------------------------------------------
	/*/{Protheus.doc} M410STTS
	Pergunta se deseja imprimir o relatório do pedido de venda, chamando a função U_MRSFAT01

	@author Thierry Pereira
	@since 27/12/2022

	@return
	/*/
//--------------------------------------------------

User Function M410STTS()

Local aArea       := GetArea()
Local nOper       := 3
Local cNumero     := SC5->C5_NUM
Local cResp 	   	 

If nOper == 3  
    IF MsgYesNo( 'Deseja Imprimir o relatorio do pedido?', 'Relatorio' )
	cResp := .t.
    else
	cResp := .f. 
	Endif
	
    mv_par01:= Cnumero         // Do Pedido                                    
    mv_par02:= cNumero         // Ate o Pedido 
    //pergunte("MTR700",)
                                      
	If cResp == .t.
    U_MSRFAT01()  		
	
	Endif

Endif

RestArea(aArea)

Return 
