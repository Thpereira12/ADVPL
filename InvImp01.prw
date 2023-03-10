#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} InvImp01

Importacao itens de inventario

@author Thierry Pereira
@since 23/01/2023

/*/

User Function InvImp01()

    Local aRet			:= {}
	Local aArea         := GetArea()

	SaveInter()

    If ParamBox({	{6,"Selecione Arquivo",PadR("",150),"",,"", 90 ,.T.,"Importacao itens de inventario","",GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE}},;
            "Importacao De Itens de inventario",@aRet)

        Processa({|| SPFatImp01( lEnd, aRet[1] )}, "Lendo arquivo csv...")

    EndIf

    RestInter()

	RestArea(aArea)

Return

//--------------------------------------------------
	/*/{Protheus.doc} EstInvImp01
	Importa registros e grava itens de inventario
	
    @author Thierry Pereira
    @since 23/01/2023
	 
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

       
        aAdd(aAuto,{'B7_FILIAL'  ,xFilial("SB7")                                                                            ,Nil})
        aAdd(aAuto,{'B7_COD'     ,Alltrim(U_NEWGENASP(aDados[nx][1]))                                                       ,Nil})
        aAdd(aAuto,{'B7_LOCAL'   ,Alltrim(U_NEWGENASP(aDados[nx][2]))                                                       ,Nil})
        aAdd(aAuto,{'B7_TIPO'    ,Alltrim(U_NEWGENASP(aDados[nx][3]))                                                       ,Nil})
        aAdd(aAuto,{'B7_DATA'    ,Stod(SubStr(aDados[nx][6],7,4) + SubStr(aDados[nx][6],4,2) + SubStr(aDados[nx][6],1,2))   ,Nil})
        aAdd(aAuto,{'B7_DTVALID' ,Stod(SubStr(aDados[nx][7],7,4) + SubStr(aDados[nx][7],4,2) + SubStr(aDados[nx][7],1,2))   ,Nil}) 
        aAdd(aAuto,{'B7_LOTECTL' ,Alltrim(U_NEWGENASP(aDados[nx][8]))                                                       ,Nil})
        aAdd(aAuto,{'B7_LOCALIZ' ,Alltrim(U_NEWGENASP(aDados[nx][9]))                                                       ,Nil})
       

        MSExecAuto({|a,b,c| MATA270(a,b,c)}, aAuto, 3, aAI0Auto)
            
        If lMsErroAuto  

            lRet := lMsErroAuto

            If lMsErroAuto
                DisarmTransaction()
            EndIf

            Conout("Inventario nao cadastrado!")

            aErrPCAuto	:= GETAUTOGRLOG()
            cMsgErro	:= ""

            For nLoop := 1 To Len(aErrPCAuto)
                cMsgErro += EncodeUTF8(StrTran(Alltrim(aErrPCAuto[nLoop]),CRLF,''))
            Next
            Conout(cMsgErro)

           FWAlertError(cMsgErro, "Erro")
            
        Else

            Conout("Inventario incluido com sucesso!")

            nConta ++
            
        EndIf

        aAuto := {}

        lMsErroAuto := .F.
    Next

	RestArea(aArea)

     FWAlertSuccess("Total de inventario inclusos: " + cValTochar(nConta) , "Inventario")

Return lRetorno
