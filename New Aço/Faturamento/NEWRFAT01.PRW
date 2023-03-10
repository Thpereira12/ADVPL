#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} NEWRFAT03

Funcao que calcula margem de rentabilidade

@author Brito
@since 06/12/2022

/*/

User Function NEWRFAT01()

Return

/*/{Protheus.doc} FAT03CAL

Realiza Calculo de Margem Bruta e Margem Liquida

@author Brito
@since 06/12/2022

/*/

User Function FAT03CAL()

    Local lRet       := .T.
    Local nLiquido   := 10
    Local nTotProd   := 0
    Local nTotItens  := 0
    Local nTotNota   := 0
    Local nTotIpi    := 0
    Local nBruto     := 0
    Local aDadosPrd  := {}
    Local nx         := 0
    Local nAliqICMS  := SuperGetMV("ZZ_ICMALI",,12) //Aliquota ICMS que devera ser oriunda da TES utilizada
    
    //Retorna impostos calculados do orcamento
    aDadosPrd := FT03IMP()

    For nx := 1 To Len(aDadosPrd)
        nTotNota += aDadosPrd[nx][2]
        nTotIpi  += (aDadosPrd[nx][2] * aDadosPrd[nx][7]) / 100
    Next
    
    nBruto := U_FT03Brt()

    //Buscamos total do produto
    //nTotProd := FT03PROD()

    //Atualizamos as margens bruta e liquidas
    M->CJ_ZZMGBRUG := nBruto
    M->CJ_ZZMGLIQ  := nLiquido

    oGetDad:oBrowse:Refresh()
    
Return lRet

/*/{Protheus.doc} FT03PROD

Retorna Total de Produto

@author Brito
@since 06/12/2022

/*/

Static Function FT03PROD()

    Local aArea     := GetArea()
    Local nTotal    := 0

    dbSelectArea("TMP1")
    dbGotop()

    While TMP1->(!EOF())
        
        nTotal += TMP1->CK_VALOR

        TMP1->(DbSkip())
    
    EndDo


    RestArea(aArea)

Return nTotal

/*/{Protheus.doc} FT03IMP

Retorna total do pedido com seus respectivos impostos

@author Brito
@since 06/12/2022

/*/

Static Function FT03IMP()

    Local aArea     := GetArea()
    Local nTotal    := 0
    Local aDados    := {}
    Local cProduto  := ""
    Local cCliente  := M->CJ_CLIENTE
    Local cLoja     := M->CJ_LOJA

    MaFisIni(cCliente,;
        cLoja,;
        "C",; 
        "N",;
        Posicione('SA1',1, xFilial("SA1") + cCliente + cLoja , 'A1_TIPOCLI') ,;
        MaFisRelImp("MT100",{"SF2","SD2"}),;
        ,;
        ,;
        "SB1",;
        "MATA461")

    nTotIPI := 0

    dbSelectArea("TMP1")
    dbGotop()

    While TMP1->(!EOF())

        nTotal += TMP1->CK_PRCVEN
        cProduto := TMP1->CK_PRODUTO

        SB1->(DbSeek(FWxFilial("SB1") + TMP1->CK_PRODUTO ))
            
        MaFisAdd(   TMP1->CK_PRODUTO,;
                    TMP1->CK_TES,;
                    TMP1->CK_QTDVEN,;
                    Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_CUSTD'),;
                    0,;
                    0,;
                    0,;
                    0,;
                    0,;
                    0,;
                    0,;
                    0,;
                    Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_CUSTD') * TMP1->CK_QTDVEN,;
                    0,;
                    0,;
                    0)
    
        nVlrFrete := MaFisRet(1,"IT_FRETE")
        nAliqICMS := MaFisRet(1,"IT_ALIQICM")	
        nAliqPIS  := MaFisRet(1,"IT_ALIQPIS")
        nAliqCof  := MaFisRet(1,"IT_ALIQCOF")
        nAliqIPI  := MaFisRet(1,"IT_ALIQIPI")

        AADD(aDados,{cProduto, nTotal,nVlrFrete,nAliqICMS,nAliqPIS,nAliqCof,nAliqIPI})

        TMP1->(DbSkip())


    EndDo

    MaFisEnd()
     
    RestArea(aArea)

Return aDados

/*/{Protheus.doc} FT03Brt

Retorna margem bruta do orçamento

@author Brito
@since 06/12/2022

/*/

User Function FT03Brt()

    Local aArea   := GetArea()
    Local nMargem := 0
    Local nCusto  := 0
    Local nPreco  := 0

    DbSelectArea("TMP1")
    DbGoTop()

    While TMP1->(!EOF())

        nCusto += Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_ZZCUST')
        nPreco += TMP1->CK_PRCVEN

        TMP1->(DbSkip())

    EndDo

    nMargem := nPreco - nCusto

    RestArea(aArea)

Return nMargem
