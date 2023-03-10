#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} SPFAT01

Importacao de Fornecedores

@author Thierry Pereira
@since 29/12/2022

/*/

User Function SPIMP01()

    Local aRet			:= {}
	Local aArea         := GetArea()

	SaveInter()

    If ParamBox({	{6,"Selecione Arquivo",PadR("",150),"",,"", 90 ,.T.,"Importacao Fornecedores","",GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE}},;
            "Importacao Fornecedores SP Acos",@aRet)

        Processa({|| SPFatImp01( lEnd, aRet[1] )}, "Lendo fornecedores arquivo csv...")

    EndIf

    RestInter()

	RestArea(aArea)

Return

//--------------------------------------------------
	/*/{Protheus.doc} SPFatImp01
	Importa registros e grava fornecedores
	
    @author Thierry Pereira
    @since 29/12/2022
	 
	@return 
	/*/
//--------------------------------------------------

Static Function SPFatImp01(lEnd, cArq)
	
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
		MsgStop("O arquivo "  + cArq + " Nao foi encontrado. A importacao sera abortada!","ATENCAO")
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

        If empty(aDados[nx][17])
			(aDados[nx][17]) := (aDados[nx][16]) 
		Endif

        nAtual++

        IncProc("Analisando fornecedor " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

       
        aAdd(aAuto,{'A2_FILIAL'  ,xFilial("SA2")                                                                            ,Nil})
        aAdd(aAuto,{'A2_COD'     ,Alltrim(U_NEWGENASP(aDados[nx][1]))                                                       ,Nil})
        aAdd(aAuto,{'A2_DTINIV'  ,Stod(SubStr(aDados[nx][2],1,4) + SubStr(aDados[nx][2],6,2) + SubStr(aDados[nx][2],9,2))   ,Nil})
        aAdd(aAuto,{'A2_LOJA'    ,"01"                                                                                      ,Nil})
        aAdd(aAuto,{'A2_TIPO'    ,"J"                                                                                       ,Nil})
        aAdd(aAuto,{'A2_EST'     ,Alltrim(aDados[nx][19])                                                                   ,Nil})
        aAdd(aAuto,{'A2_END'     ,Alltrim(U_NEWGENASP(aDados[nx][11]))                                                      ,Nil})
        aAdd(aAuto,{'A2_BAIRRO'  ,Alltrim(aDados[nx][3])                                                                    ,Nil}) 
        aAdd(aAuto,{'A2_CEP'     ,Alltrim(U_NEWGENASP(aDados[nx][4]))                                                       ,Nil})
        aAdd(aAuto,{'A2_MUN'     ,Alltrim(aDados[nx][5])                                                                    ,Nil})
        aAdd(aAuto,{'A2_CNAE'    ,Alltrim(U_NEWGENASP(aDados[nx][6]))                                                       ,Nil})
        aAdd(aAuto,{'A2_CGC'     ,Alltrim(U_NEWGENASP(aDados[nx][7]))                                                       ,Nil})
        aAdd(aAuto,{'A2_PAIS'    ,"105"                                                                                     ,Nil})
        aAdd(aAuto,{'A2_EMAIL'   ,Alltrim(aDados[nx][10])                                                                   ,Nil})
        aAdd(aAuto,{'A2_FAX'     ,Alltrim(U_NEWGENASP(aDados[nx][12]))                                                      ,Nil})
        aAdd(aAuto,{'A2_TEL'     ,Alltrim(U_NEWGENASP(aDados[nx][13]))                                                      ,Nil})
        aAdd(aAuto,{'A2_ZZTEL2'  ,Alltrim(U_NEWGENASP(aDados[nx][14]))                                                      ,Nil})
        aAdd(aAuto,{'A2_INSCR'   ,Alltrim(U_NEWGENASP(aDados[nx][15]))                                                      ,Nil})
        aAdd(aAuto,{'A2_NREDUZ'  ,Alltrim(U_NEWGENASP(aDados[nx][17]))                                                      ,Nil})
        aAdd(aAuto,{'A2_NOME'    ,Alltrim(aDados[nx][16])                                                                   ,Nil})
        aAdd(aAuto,{'A2_ZZSITE'  ,Alltrim(aDados[nx][18])                                                                   ,Nil})

        MSExecAuto({|a,b,c| MATA020(a,b,c)}, aAuto, 3, aAI0Auto)
            
        If lMsErroAuto  

            lRet := lMsErroAuto

            If lMsErroAuto
                DisarmTransaction()
            EndIf

            Conout("Fornecedor nao cadastrado!")

            aErrPCAuto	:= GETAUTOGRLOG()
            cMsgErro	:= ""

            For nLoop := 1 To Len(aErrPCAuto)
                cMsgErro += EncodeUTF8(StrTran(Alltrim(aErrPCAuto[nLoop]),CRLF,''))
            Next
            Conout(cMsgErro)

           FWAlertError(cMsgErro, "Erro")
            
        Else

            Conout("Fornecedor incluido com sucesso!")

            nConta ++
            
        EndIf

        aAuto := {}

        lMsErroAuto := .F.
    Next

	RestArea(aArea)

     FWAlertSuccess("Total de fornecedores inclusos: " + cValTochar(nConta) , "Fornecedores")

Return lRetorno
