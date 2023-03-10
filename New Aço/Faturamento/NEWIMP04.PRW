#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} NEWFAT04

Importaçao de Clientes

@author Brito
@since 22/11/2022

/*/

User Function NEWIMP04()

    Local aRet			:= {}
	Local aArea         := GetArea()

	SaveInter()

    If ParamBox({	{6,"Selecione Arquivo",PadR("",150),"",,"", 90 ,.T.,"Importacao Clientes","",GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE}},;
            "Importacao Clientes New Aço",@aRet)

        Processa({|| NewCliImp01( lEnd, aRet[1] )}, "Lendo clientes arquivo csv...")

    EndIf

    RestInter()

	RestArea(aArea)

Return

//--------------------------------------------------
	/*/{Protheus.doc} NewCliImp01
	Importa registros e grava clientes
	
    @author Brito
    @since 22/11/2022
	 
	@return 
	/*/
//--------------------------------------------------

Static Function NewCliImp01(lEnd, cArq)
	
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
    Local cCodigo     := ""
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
		MsgStop("O arquivo "  + cArq + " nao foi encontrado. A importaçao sera abortada!","ATENCAO")
		Return
	EndIf
 
	FT_FUSE(cArq)
	FT_FGOTOP()

	nTot2 := FT_FLASTREC()

	While !FT_FEOF()

		nNumCob := nNumCob + 1

		cLinha := FT_FREADLN()
 
		If lPrim
			aCampos := Separa(cLinha,";",.T.)
			lPrim := .F.
		Else
			AADD(aDados,Separa(cLinha,";",.T.))
		EndIf
 
		FT_FSKIP()
	EndDo

	nTotal := Len(aDados)

    ProcRegua(nTotal)

    For nx := 1 To Len(aDados)

        nAtual++

        IncProc("Analisando cliente " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

        aAdd(aAuto,{'A1_FILIAL'  ,xFilial("SA2")                                                                            ,Nil})
        //aAdd(aAuto,{'A1_COD'     ,cCodigo                                                                                   ,Nil})
        aAdd(aAuto,{'A1_PESSOA'  ,aDados[nx][14]                                                                            ,Nil})
        aAdd(aAuto,{'A1_LOJA'    ,"01"                                                                                      ,Nil})
        aAdd(aAuto,{'A1_NOME'    ,Alltrim(aDados[nx][3])                                                                    ,Nil})
        aAdd(aAuto,{'A1_NREDUZ'  ,Alltrim(aDados[nx][3])                                                                    ,Nil})
        aAdd(aAuto,{'A1_END'     ,Alltrim(aDados[nx][4])                                                                    ,Nil}) 
        aAdd(aAuto,{'A1_ENDCOB'  ,Alltrim(aDados[nx][4])                                                                    ,Nil}) 
        aAdd(aAuto,{'A1_ENDENT'  ,Alltrim(aDados[nx][4])                                                                    ,Nil}) 
        aAdd(aAuto,{'A1_TIPO'    ,"F"                                                                                       ,Nil})
        aAdd(aAuto,{'A1_BAIRRO'  ,Alltrim(aDados[nx][5])                                                                    ,Nil}) 
        aAdd(aAuto,{'A1_EST'     ,Alltrim(aDados[nx][13])                                                                   ,Nil})
        aAdd(aAuto,{'A1_MUN'     ,Alltrim(aDados[nx][6])                                                                    ,Nil})
        aAdd(aAuto,{'A1_PAIS'    ,'105'                                                                                     ,Nil})
        aAdd(aAuto,{'A1_CGC'     ,U_convStr(U_NEWGENASP(aDados[nx][9]))                                                     ,Nil})
        aAdd(aAuto,{'A1_INSCR'   ,U_NEWGENASP(aDados[nx][10])                                                               ,Nil})
        aAdd(aAuto,{'A1_ZZCDLEG' ,Alltrim(U_NEWGENASP(aDados[nx][2]))                                                       ,Nil})

        MSExecAuto({|a,b,c| MATA030(a,b,c)}, aAuto, 3, aAI0Auto)
            
        If lMsErroAuto  

            lRet := lMsErroAuto

            If lMsErroAuto
                DisarmTransaction()
            EndIf

            Conout("Cliente nao cadastrado!")

            /*aErrPCAuto	:= GETAUTOGRLOG()
            cMsgErro	:= ""

            For nLoop := 1 To Len(aErrPCAuto)
                cMsgErro += EncodeUTF8(StrTran(Alltrim(aErrPCAuto[nLoop]),CRLF,''))
            Next
            Conout(cMsgErro)

           FWAlertError(cMsgErro, "Erro")*/

            
        Else

            Conout("Cliente incluido com sucesso!")

            nConta ++
            
        EndIf

        aAuto := {}
        
        lMsErroAuto := .F.
    Next

	RestArea(aArea)

     FWAlertSuccess("Total de clientes inclusos: " + cValTochar(nConta) , "Clientes")

Return lRetorno
