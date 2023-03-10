#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} NEWFAT02

importacao de Produtos

@author Brito
@since 22/11/2022

/*/

User Function NEWIMP02()

    Local aRet			:= {}
	Local aArea         := GetArea()

	SaveInter()

    If ParamBox({	{6,"Selecione Arquivo",PadR("",150),"",,"", 90 ,.T.,"Importacao Produtos","",GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE}},;
            "Importacao Produtos New Aço",@aRet)

        MsgRun("Lendo produtos arquivo csv...", "Titulo", {|| NewPrdImp01( lEnd, aRet[1] ) })

    EndIf

    RestInter()

	RestArea(aArea)

Return

//--------------------------------------------------
	/*/{Protheus.doc} NewPrdImp01
	Importa registros e grava produtos
	
    @author Brito
    @since 22/11/2022
	 
	@return 
	/*/
//--------------------------------------------------

Static Function NewPrdImp01(lEnd, cArq)
	
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
    Local nLoop       := 0
    Local cMsgErro    := ''
    Local aErrPCAuto  := {}
    Local aAI0Auto    := {}
    Local cCodigo     := ""
    Local cNcm        := ""
    Local aProd       := {}
    Local lRetorno    := .F.
    Local nConta      := 0
	
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

    For nx := 1 To Len(aDados)

        cNcm := Alltrim(aDados[nx][20])
        cNcm := StrTran(cNcm,",","")

        cCodigo := GetSXENum( "SB1", "B1_COD" ) 

        ConfirmSx8("SB1", "B1_COD")

        //Verificar com Emerson qual campo é o custo padrão dentro do sistema atual 'B1_CUSTD'

        aProd :=       {{'B1_FILIAL'    ,xFilial("SB1")                                                              ,Nil},;
                        {'B1_COD'       ,cCodigo                                                                     ,Nil},;
                        {'B1_DESC'      ,Alltrim(aDados[nx][2])                                                      ,Nil},;
                        {'B1_TIPO'      ,"ME"                                                                        ,Nil},;
                        {'B1_UM'        ,aDados[nx][32]                                                              ,Nil},;
                        {'B1_LOCPAD'    ,"01"                                                                        ,Nil},;
                        {'B1_ORIGEM'    ,"0"                                                                         ,Nil},;
                        {'B1_GRUPO'     ,StrZero(Val(StrTran(Alltrim(aDados[nx][79]),'"',"")),TamSx3("BM_GRUPO")[1]) ,Nil},;
                        {'B1_PESO'      ,Val(aDados[nx][21])                                                         ,Nil},;
                        {'B1_POSIPI'    ,cNcm                                                                        ,Nil},;
                        {'B1_PICM'      ,Val(aDados[nx][55])                                                         ,Nil},;
                        {'B1_ZZCDLEG'   ,Alltrim(StrTran(aDados[nx][1],'"',''))                                      ,Nil},;
                        {'B1_ZZVLREF'   ,Val(aDados[nx][10])                                                         ,Nil},;
                        {'B1_ZZMAR1'    ,Val(aDados[nx][8])                                                          ,Nil},;
                        {'B1_ZZMAR2'    ,Val(aDados[nx][9])                                                          ,Nil},;
                        {'B1_ZZFAT'     ,Val(aDados[nx][6])                                                          ,Nil},;
                        {'B1_ZZMG1'     ,Val(aDados[nx][4])                                                          ,Nil},;
                        {'B1_ZZMG2'     ,Val(aDados[nx][5])                                                          ,Nil},;
                        {'B1_ZZMD'      ,Val(aDados[nx][22])                                                         ,Nil},;
                        {'B1_ZZMD1'     ,Val(aDados[nx][23])                                                         ,Nil},;
                        {'B1_ZZPRC1'    ,Val(aDados[nx][24])                                                         ,Nil},;
                        {'B1_ZZCUST'    ,Val(aDados[nx][7])                                                          ,Nil},;
                        {'B1_ZZPRC2'    ,Val(aDados[nx][25])                                                         ,Nil}}


        MSExecAuto({|x,y| Mata010(x,y)},aProd,3)
            
        If lMsErroAuto  

            lRet := lMsErroAuto

            /*If lMsErroAuto
                DisarmTransaction()
            EndIf

            Conout("Produto não cadastrado!")

            MostraErro()

            aErrPCAuto	:= GETAUTOGRLOG()
            cMsgErro	:= ""

            For nLoop := 1 To Len(aErrPCAuto)
                cMsgErro += EncodeUTF8(StrTran(Alltrim(aErrPCAuto[nLoop]),CRLF,''))
            Next
            Conout(cMsgErro)

           FWAlertError(cMsgErro, "Erro")*/
            
        Else

            nConta ++

            ConfirmSx8()

            Conout("Produto incluido com sucesso!")
            
        EndIf

        aProd := {}

        lMsErroAuto := .F.

    Next

	RestArea(aArea)

    FWAlertSuccess("Total de produtos inclusos: " + cValTochar(nConta) , "Produtos")

Return lRetorno


/*/{Protheus.doc} convStr

Retira caracteres especiais

@author		André Brito
@since		16/12/2022
@version	12.1.33
/*/

User Function convStr(cConteudo)

Local u := 0

Default cConteudo := ""

    for u := 1 to len(cConteudo)
        If at('.', cConteudo) > 0
            cConteudo := strtran(cConteudo,".","")
        ElseIf at('-', cConteudo) > 0
            cConteudo := strtran(cConteudo,"-","")
        ElseIf at('\', cConteudo) > 0
            cConteudo := strtran(cConteudo,"\","")
        ElseIf at('/', cConteudo) > 0
            cConteudo := strtran(cConteudo,"/","")
        ElseIf at(',', cConteudo) > 0
            cConteudo := strtran(cConteudo,","," ")
        EndIf
    Next
    
Return cConteudo

