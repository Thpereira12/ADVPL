#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} SPFAT01

Importacao de Clientes

@author Thierry Pereira
@since 29/12/2022

/*/

User Function SPIMP02()

    Local aRet			:= {}
	Local aArea         := GetArea()

	SaveInter()

    If ParamBox({	{6,"Selecione Arquivo",PadR("",150),"",,"", 90 ,.T.,"Importacao Clientes","",GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE}},;
            "Importacao Clientes SP Acos",@aRet)

        Processa({|| SPFatImp02( lEnd, aRet[1] )}, "Lendo clientes arquivo csv...")

    EndIf

    RestInter()

	RestArea(aArea)

Return

//--------------------------------------------------
	/*/{Protheus.doc} SPFatImp02
	Importa registros e grava clientes
	
    @author Thierry Pereira
    @since 29/12/2022
	 
	@return 
	/*/
//--------------------------------------------------

Static Function SPFatImp02(lEnd, cArq)
	
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
    Local cEmail      := 0
    Local cEmail2      := 0 
	
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

        If empty(aDados[nx][6])
			(aDados[nx][6]) := (aDados[nx][10]) 
		Endif
        
        If empty(aDados[nx][33])
			(aDados[nx][33]) := (aDados[nx][34]) 
		Endif

       cEmail := Alltrim(aDados[nx][19])
       cEmail := StrTran(cEmail,";","")

       cEmail2 := Alltrim(aDados[nx][20])
       cEmail2 := StrTran(cEmail2,";","")

        nAtual++

        IncProc("Analisando cliente " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

       
        aAdd(aAuto,{'A1_FILIAL'  ,xFilial("SA1")                                                                             ,Nil})
        aAdd(aAuto,{'A1_COD'     ,Alltrim(U_NEWGENASP(aDados[nx][1]))                                                        ,Nil})
        aAdd(aAuto,{'A1_DTCAD'   ,Stod(SubStr(aDados[nx][2],1,4) + SubStr(aDados[nx][2],6,2) + SubStr(aDados[nx][2],9,2))    ,Nil})
        aAdd(aAuto,{'A1_LOJA'    ,"01"                                                                                       ,Nil})
        aAdd(aAuto,{'A1_TIPO'    ,"F"                                                                                        ,Nil})
        aAdd(aAuto,{'A1_EST'     ,Alltrim(aDados[nx][53])                                                                    ,Nil})
        aAdd(aAuto,{'A1_END'     ,Alltrim(U_NEWGENASP(aDados[nx][51])) + Alltrim(U_NEWGENASP(aDados[nx][52]))                ,Nil})
        aAdd(aAuto,{'A1_BAIRRO'  ,Alltrim(aDados[nx][47])                                                                    ,Nil}) 
        aAdd(aAuto,{'A1_CEP'     ,Alltrim(U_NEWGENASP(aDados[nx][48]))                                                       ,Nil})
        aAdd(aAuto,{'A1_MUN'     ,Alltrim(aDados[nx][49])                                                                    ,Nil})
        aAdd(aAuto,{'A1_COMPLEM' ,Alltrim(aDados[nx][50])                                                                    ,Nil}) 
        aAdd(aAuto,{'A1_CNAE'    ,Alltrim(U_NEWGENASP(aDados[nx][5]))                                                        ,Nil})
        aAdd(aAuto,{'A1_CGC'     ,Alltrim(U_NEWGENASP(aDados[nx][6]))                                                        ,Nil})
        aAdd(aAuto,{'A1_PAIS'    ,"105"                                                                                      ,Nil})
        aAdd(aAuto,{'A1_ULTCOM'  ,Stod(SubStr(aDados[nx][12],7,4) + SubStr(aDados[nx][12],4,2) + SubStr(aDados[nx][12],1,2)) ,Nil})  
        aAdd(aAuto,{'A1_PRF_VLD' ,Stod(SubStr(aDados[nx][13],7,4) + SubStr(aDados[nx][13],4,2) + SubStr(aDados[nx][13],1,2)) ,Nil})
        aAdd(aAuto,{'A1_PRICOM'  ,Stod(SubStr(aDados[nx][18],7,4) + SubStr(aDados[nx][18],4,2) + SubStr(aDados[nx][18],1,2)) ,Nil})   
        aAdd(aAuto,{'A1_EMAIL'   ,cEmail                                                                                     ,Nil})
        aAdd(aAuto,{'A1_ZZEMFIS' ,cEmail2                                                                                    ,Nil})
        aAdd(aAuto,{'A1_FAX'     ,Alltrim(U_NEWGENASP(aDados[nx][22]))                                                       ,Nil})
        aAdd(aAuto,{'A1_TEL'     ,Alltrim(U_NEWGENASP(aDados[nx][24]))                                                       ,Nil})
        aAdd(aAuto,{'A1_ZZTEL2'  ,Alltrim(U_NEWGENASP(aDados[nx][25]))                                                       ,Nil})
        aAdd(aAuto,{'A1_INSCR'   ,Alltrim(U_NEWGENASP(aDados[nx][29]))                                                       ,Nil})
        aAdd(aAuto,{'A1_NREDUZ'  ,Alltrim(U_NEWGENASP(aDados[nx][33]))                                                       ,Nil})
        aAdd(aAuto,{'A1_NOME'    ,Alltrim(aDados[nx][34])                                                                    ,Nil})
        aAdd(aAuto,{'A1_ZZSITE'  ,Alltrim(aDados[nx][37])                                                                    ,Nil})

        MSExecAuto({|a,b,c| MATA030(a,b,c)}, aAuto, 3, aAI0Auto)
            
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
