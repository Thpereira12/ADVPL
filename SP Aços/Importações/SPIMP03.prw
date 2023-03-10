#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} SPFAT01

Importacao de Produtos 

@author Thierry Pereira
@since 29/12/2022

/*/

User Function SPIMP03()

    Local aRet			:= {}
	Local aArea         := GetArea()

	SaveInter()

    If ParamBox({	{6,"Selecione Arquivo",PadR("",150),"",,"", 90 ,.T.,"Importacao Produtos","",GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE}},;
            "Importacao Produtos SP Acos",@aRet)

        Processa({|| SPFatImp03( lEnd, aRet[1] )}, "Lendo clientes arquivo csv...")

    EndIf

    RestInter()

	RestArea(aArea)

Return

//--------------------------------------------------
	/*/{Protheus.doc} SPFatImp03
	Importa registros e grava produtos
	
    @author Thierry Pereira
    @since 29/12/2022
	 
	@return 
	/*/
//--------------------------------------------------

Static Function SPFatImp03(lEnd, cArq)
	
	Local aArea       := GetArea()
	Local aCampos     := {}
	Local aDados      := {}
    Local aAuto       := {}
	Local lPrim       := .T.
	Local cLinha      := ""
	Local nTotal      := 0
	Local nTot2       := 0
	Local nNumCob     := 0
	Local nx          := 0
    Local lRet        := .T.
    Local aAI0Auto    := {}
    Local lRetorno    := .F.
    Local nConta      := 0
    Local nAtual      := 0 
    Local nLoop       := 0
	
    Private lMsErroAuto     as logical
	Private lMsHelpAuto	    as logical
	Private lAutoErrNoFile  as logical
	Private aErro     := {}
	Private HrIn      := Time()    
	Private HrFin
	Private aErros    := {}

    lMsErroAuto 	:= .F.
	lMsHelpAuto		:= .T.
	lAutoErrNoFile	:= .T.

 
	If !File(cArq)
		MsgStop("O arquivo "  + cArq + " nao foi encontrado. A importacao sera abortada!","ATENCAO")
		Return
	EndIf
 
	FT_FUSE(cArq) //Le o arquivo de texto
	FT_FGOTOP()   //Posiciona na primeira linha

	nTot2 := FT_FLASTREC() // Retorna o número de linhas do arquivo

	While !FT_FEOF()

		nNumCob := nNumCob + 1

		cLinha := FT_FREADLN() // Retorna a linha corrente 
 
		If lPrim
			aCampos := Separa(cLinha,";",.T.)
			lPrim := .F.
		Else
			AADD(aDados,Separa(cLinha,";",.T.))
		EndIf
 
		FT_FSKIP() // Pula para próxima linha 
	EndDo

	nTotal := Len(aDados)

    ProcRegua(nTotal)

    For nx := 1 To Len(aDados)

          

        nAtual++

        IncProc("Analisando cliente " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

       
        aAdd(aAuto,{'B1_FILIAL'  ,xFilial("SB1")                                                                             ,Nil})
        aAdd(aAuto,{'B1_COD'     ,Alltrim(U_NEWGENASP(aDados[nx][1]))                                                        ,Nil})
        aAdd(aAuto,{'B1_TIPO'    ,"ME"                                                                                       ,Nil})
        aAdd(aAuto,{'B1_UM'      ,Alltrim(U_NEWGENASP(aDados[nx][21]))                                                       ,Nil})
        aAdd(aAuto,{'B1_SEGUM'   ,Alltrim(U_NEWGENASP(aDados[nx][22]))                                                       ,Nil})
        aAdd(aAuto,{'B1_LOCPAD'  ,"01"                                                                                       ,Nil})
        aAdd(aAuto,{'B1_ORIGEM'  ,"0"                                                                                        ,Nil})
        aAdd(aAuto,{'B1_IPI'     ,Val(Alltrim(U_NEWGENASP(aDados[nx][3])))                                                        ,Nil})
        aAdd(aAuto,{'B1_DESC'    ,Alltrim(U_NEWGENASP(aDados[nx][9]))                                                        ,Nil})
        aAdd(aAuto,{'B1_ZZMG1'   ,Alltrim(aDados[nx][11])                                                                    ,Nil})                             
        aAdd(aAuto,{'B1_ZZMG2'   ,Alltrim(aDados[nx][12])                                                                    ,Nil})
        aAdd(aAuto,{'B1_PRV1'    ,Alltrim(aDados[nx][14])                                                                    ,Nil})
        aAdd(aAuto,{'B1_ZZMD'    ,Alltrim(aDados[nx][15])                                                                    ,Nil})
        aAdd(aAuto,{'B1_ZZMD1'   ,Alltrim(aDados[nx][16])                                                                    ,Nil})

        MSExecAuto({|a,b,c| MATA010(a,b,c)}, aAuto, 3, aAI0Auto)
            
        If lMsErroAuto  

            lRet := lMsErroAuto

            If lMsErroAuto
                DisarmTransaction()
            EndIf

            Conout("Cliente nao cadastrado!")

            aErrPCAuto	:= GETAUTOGRLOG()
            cMsgErro	:= ""

            For nLoop := 1 To Len(aErrPCAuto)
                cMsgErro += EncodeUTF8(StrTran(Alltrim(aErrPCAuto[nLoop]),CRLF,''))
            Next
            Conout(cMsgErro)

           FWAlertError(cMsgErro, "Erro")
            
        Else

            Conout("Cliente incluido com sucesso!")

            nConta ++
            
        EndIf

        aAuto := {}

        lMsErroAuto := .F.
    Next

	RestArea(aArea)

     FWAlertSuccess("Total de clientes inclusos: " + cValTochar(nConta) , "clientes")

Return lRetorno
