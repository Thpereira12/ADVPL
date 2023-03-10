#Include 'Protheus.ch'

/*
CN100VST - Validar a alteração da situação do contrato

André Brito

18/02/2023
*/

User Function CN100VST()

    Local aArea   := GetArea()
    Local cNew    := PARAMIXB[1]
    Local cContr  := PARAMIXB[2]
    Local cRevisa := PARAMIXB[3]
    Local nLoop   := 0
    Local aRatCtb := {}
    Local aRatFin := {}
    Local lRet    := .T.

    If cNew == "04" .Or. cNew == "05"
        aRatCtb := U_RatCtbCtr(cContr)
        aRatFin := U_RatPlFin(cContr)

        For nLoop := 1 To Len(aRatFin)
            lRet := U_CN1ORCRE(StrTran(aRatFin[nLoop][1],"/",""),aRatFin[nLoop][2],aRatCtb)
            If !lRet
                Exit
            EndIf 
        Next
    EndIf 

    RestArea(aArea)

Return lRet

/*
CN1ORCRE - Busca saldos orçados e realizados das entidades contabéis passadas como parametros

André Brito

18/02/2023
*/

User Function CN1ORCRE(cPeriodo,nValor,aEntCtb)

    Local cQuery      := ""
    Local cTmp        := {}
    Local cConta      := ""
    Local cCusto      := ""
    Local nQtdReg     := 0
    Local nPercentual := 0
    Local nVlrPerc    := 0
    Local nVlrReal    := 0
    Local nx          := 0
    Local nOrcado     := 0
    Local nRealizado  := 0
    Local nSaldo      := 0
    Local cMsg        := ""
    Local lRetorno    := .T.

    For nx := 1 To Len(aEntCtb)

        cTmp   := GetNextAlias()
        cConta := aEntCtb[nx][2]
        cCusto := aEntCtb[nx][3]

        cQuery := "SELECT MASTER.CODCONTACONTABIL "
        cQuery += ",MASTER.CTARES "
        cQuery += ",MASTER.DESCRICAOCONTACONTABIL "
        cQuery += ",MASTER.TIPOCONTA "
        cQuery += ",MASTER.CENTRODECUSTO "
        cQuery += ",MASTER.CCRES "
        cQuery += ",MASTER.DESCRICAOCENTROCUSTO "
        cQuery += ",MASTER.TIPOCENTROCUSTO "
        cQuery += ",MASTER.CODIGOCONTASUPERIOR "
        cQuery += ",MASTER.DESCRICAOCONTASUPERIOR "
        cQuery += ",MASTER.DIADOSALDO "
        cQuery += ",MASTER.ORCADO "
        cQuery += ",MASTER.REALIZADO " 
        cQuery += ",IIF(MASTER.REALIZADO > 0,(MASTER.ORCADO - MASTER.REALIZADO) / MASTER.REALIZADO,0)  DESVIO "
        cQuery += "FROM "
        cQuery += "(SELECT CT1_CONTA      CODCONTACONTABIL, "
        cQuery += "CT1_RES                CTARES, "
        cQuery += "CT1_DESC01             DESCRICAOCONTACONTABIL, "
        cQuery += "CT1_CLASSE             TIPOCONTA, "
        cQuery += "ARQ2.CTT_CUSTO         CENTRODECUSTO, " 
        cQuery += "ARQ2.CTT_RES           CCRES, "
        cQuery += "ARQ2.CTT_DESC01        DESCRICAOCENTROCUSTO, "
        cQuery += "ARQ2.CTT_CLASSE        TIPOCENTROCUSTO, "
        cQuery += "ARQ2.CTT_CCSUP         CODIGOCONTASUPERIOR, "
        cQuery += "ARQ_INFO.CTT_DESC01    DESCRICAOCONTASUPERIOR, "
        cQuery += "CQ3_DATA               DIADOSALDO, "
        cQuery += "(SELECT ( (COALESCE(Sum(CQ3_CREDIT) - Sum(CQ3_DEBITO),0) ) * -1) "
        cQuery += "FROM " + RetSqlName("CQ3") + " CQ3 "
        cQuery += "WHERE  CQ3_FILIAL = '" + xFilial("CQ3") + "' "
        cQuery += "AND CQ3_MOEDA = '01' "
        cQuery += "AND CQ3_TPSALD = '0' "
        cQuery += "AND CQ3_CONTA = ARQ.CT1_CONTA "
        cQuery += "AND CQ3_CCUSTO = ARQ2.CTT_CUSTO "
        cQuery += "AND CQ3_DATA = ARQ1.CQ3_DATA "
        cQuery += "AND CQ3_DATA BETWEEN '" + SubStr(cPeriodo,3,4) + SubStr(cPeriodo,1,2) +  "01' AND '" + SubStr(cPeriodo,3,4) + SubStr(cPeriodo,1,2) + "31' "
        cQuery += "AND CQ3_CONTA = '" + cConta + "' "
        cQuery += "AND CQ3_CCUSTO = '" + cCusto + "' "
        cQuery += "AND CQ3.D_E_L_E_T_ = ' ') AS ORCADO, "
        cQuery += "(SELECT ( COALESCE(Sum(CQ3_CREDIT) - Sum(CQ3_DEBITO),0) ) * -1 "
        cQuery += "FROM " + RetSqlName("CQ3") + " CQ3 "
        cQuery += "WHERE  CQ3_FILIAL = '01' "
        cQuery += "AND CQ3_MOEDA = '01' "
        cQuery += "AND CQ3_TPSALD = '1' "
        cQuery += "AND CQ3_CONTA = ARQ.CT1_CONTA "
        cQuery += "AND CQ3_CCUSTO = ARQ2.CTT_CUSTO "
        cQuery += "AND CQ3_DATA = ARQ1.CQ3_DATA "
        cQuery += "AND CQ3_DATA BETWEEN '" + SubStr(cPeriodo,3,4) + SubStr(cPeriodo,1,2) + "01' AND '" + SubStr(cPeriodo,3,4) + SubStr(cPeriodo,1,2) + "31' "
        cQuery += "AND CQ3_CONTA = '" + cConta + "' "
        cQuery += "AND CQ3_CCUSTO = '" + cCusto + "' "
        cQuery += "AND CQ3.D_E_L_E_T_ = ' ') AS REALIZADO "
        cQuery += "FROM  " + RetSqlName("CT1") + " ARQ, "
        cQuery += "" + RetSqlName("CQ3") + " ARQ1, "
        cQuery += "" + RetSqlName("CTT") + " ARQ2 "
        cQuery += "LEFT JOIN " + RetSqlName("CTT") + " ARQ_INFO "
        cQuery += "ON 1 = 1 "
        cQuery += "AND ARQ_INFO.CTT_FILIAL = ARQ2.CTT_FILIAL "
        cQuery += "AND ARQ_INFO.CTT_CUSTO = ARQ2.CTT_CCSUP "
        cQuery += "AND ARQ_INFO.D_E_L_E_T_ = ' ' "
        cQuery += "WHERE  ARQ2.CTT_FILIAL = '" + xFilial("CTT") + "' "
        cQuery += "AND ARQ2.CTT_CLASSE = '2' "
        cQuery += "AND ARQ2.CTT_CUSTO = '" + cCusto + "' "
        cQuery += "AND ARQ.CT1_FILIAL = '" + xFilial("CT1") + "' "
        cQuery += "AND ARQ.CT1_CONTA = '" + cConta + "'
        cQuery += "AND ARQ.CT1_CLASSE = '2' "
        cQuery += "AND ARQ.D_E_L_E_T_ = ' ' "
        cQuery += "AND ARQ2.D_E_L_E_T_ = ' ' "
        cQuery += "AND ARQ1.CQ3_CONTA = ARQ.CT1_CONTA "
        cQuery += "AND ARQ1.CQ3_CCUSTO = ARQ2.CTT_CUSTO "
        cQuery += "AND ( (SELECT ( COALESCE(Sum(CQ3_CREDIT) - Sum(CQ3_DEBITO),0) ) * -1 "
        cQuery += "FROM " + RetSqlName("CQ3") + " CQ3 "
        cQuery += "WHERE  CQ3_FILIAL = '" + xFilial("CQ3") + "' "
        cQuery += "AND CQ3_MOEDA = '01' "
        cQuery += "AND CQ3_TPSALD = '0' "
        cQuery += "AND CQ3_CONTA = ARQ.CT1_CONTA "
        cQuery += "AND CQ3_CCUSTO = ARQ2.CTT_CUSTO "
        cQuery += "AND CQ3_DATA = ARQ1.CQ3_DATA "
        cQuery += "AND CQ3_CONTA = '" + cConta + "' "
        cQuery += "AND CQ3_CCUSTO = '" + cCusto + "' "
        cQuery += "AND CQ3_DATA BETWEEN '" + SubStr(cPeriodo,3,4) + SubStr(cPeriodo,1,2) + "01' AND '" + SubStr(cPeriodo,3,4) + SubStr(cPeriodo,1,2) + "31' "
        cQuery += "AND CQ3.D_E_L_E_T_ = ' ') <> 0 "
        cQuery += "OR (SELECT ( COALESCE(Sum(CQ3_CREDIT) - Sum(CQ3_DEBITO),0) ) * -1 "
        cQuery += "FROM  " + RetSqlName("CQ3") + " CQ3 "
        cQuery += "WHERE  CQ3_FILIAL = '" + xFilial("CQ3") + "' "
        cQuery += "AND CQ3_MOEDA = '01' "
        cQuery += "AND CQ3_TPSALD = '1' "
        cQuery += "AND CQ3_CONTA = ARQ.CT1_CONTA "
        cQuery += "AND CQ3_CCUSTO = ARQ2.CTT_CUSTO "
        cQuery += "AND CQ3_CONTA = '" + cConta + "' "
        cQuery += "AND CQ3_CCUSTO = '" + cCusto + "' "
        cQuery += "AND CQ3_DATA = ARQ1.CQ3_DATA "
        cQuery += "AND CQ3_DATA BETWEEN '" + SubStr(cPeriodo,3,4) + SubStr(cPeriodo,1,2) + "01' AND '" + SubStr(cPeriodo,3,4) + SubStr(cPeriodo,1,2) + "31' "
        cQuery += "AND CQ3.D_E_L_E_T_ = ' ') <> 0 ) "
        cQuery += "GROUP  BY CT1_CONTA, "
        cQuery += "CT1_RES, "
        cQuery += "CT1_DESC01, "
        cQuery += "CT1_CLASSE, "
        cQuery += "CT1_CTASUP, "
        cQuery += "ARQ2.CTT_CUSTO, "
        cQuery += "ARQ2.CTT_RES, "
        cQuery += "ARQ2.CTT_DESC01, "
        cQuery += "ARQ2.CTT_CLASSE, "
        cQuery += "ARQ2.CTT_CCSUP, "
        cQuery += "CQ3_DATA, "
        cQuery += "ARQ_INFO.CTT_DESC01 "
        cQuery += ") MASTER"    

        cQuery := ChangeQuery(cQuery)

        DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cTmp,.F.,.F.) 

        Count To nQtdReg

        If nQtdReg >0
            (cTmp)->(DbGoTop())
    
            nOrcado    := (cTmp)->ORCADO
            nRealizado := (cTmp)->REALIZADO

            If nRealizado < 0                 
               nRealizado := Abs(nRealizado)
            EndIf 

            If nOrcado < 0                 
               nOrcado := Abs(nOrcado)
            EndIf

            nSaldo := nOrcado - nRealizado

            nPercentual := aEntCtb[nx][1]
            nVlrPerc    := nValor / 100
            nVlrReal    := nVlrPerc * nPercentual

            (cTmp)->(DbCloseArea())
        EndIf

        If nVlrReal > nSaldo
            
            cMsg := "Não existe saldo disponível para a conta: " + Alltrim(aEntCtb[nx][2]) + " - " + Alltrim(Posicione("CT1",1,xFilial("CT1")+aEntCtb[nx][2],"CT1_DESC01")) + " "
            cMsg += "e centro de custo " + Alltrim(aEntCtb[nx][3]) + " - " + Alltrim(Posicione("CTT",1,xFilial("CTT")+aEntCtb[nx][3],"CTT_DESC01")) + " "

            Aviso("Saldo", cMsg, {"OK"}, 1)
            lRetorno := .F.
        EndIf 

        If !lRetorno    
            Exit
        EndIf 
    Next

Return lRetorno

/*
RatCtbCtr - Busca rateio contabil utilizado na inclusao do contrato

André Brito

18/02/2023
*/

User Function RatCtbCtr(cNumCtr) 

    Local cQuery  := ""
    Local cTmpCtb := GetNextAlias()
    Local aDados  := {}

    cQuery := "SELECT CNZ_PERC, "
    cQuery += "CNZ_CONTA, "
    cQuery += "CNZ_CC, "
    cQuery += "CNZ_ITEMCT "
    cQuery += "FROM " + RetSqlName("CNZ") + ""
    cQuery += "WHERE  CNZ_CONTRA = '" + cNumCtr + "' "
    cQuery += "AND D_E_L_E_T_ = ' '  "

    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cTmpCtb,.F.,.F.) 

    (cTmpCtb)->(DbGoTop())
    
    While (cTmpCtb)->(!EOF())
        
        AADD(aDados,{(cTmpCtb)->CNZ_PERC,(cTmpCtb)->CNZ_CONTA,(cTmpCtb)->CNZ_CC,(cTmpCtb)->CNZ_ITEMCT})

        (cTmpCtb)->(DbSkip())

    EndDo 

    (cTmpCtb)->(DbCloseArea())

Return aDados

/*
RatPlFin - Busca planilha financeira do contrato

André Brito

18/02/2023
*/

User Function RatPlFin(cNum) 

    Local cQuery  := ""
    Local cTmpPla := GetNextAlias()
    Local aDados  := {}

    cQuery :="SELECT CNF_COMPET, "
    cQuery +="CNF_VLPREV "
    cQuery +="FROM " + RetSqlName("CNF") + " "
    cQuery +="WHERE  CNF_CONTRA = '" + cNum + "' "
    cQuery +="AND D_E_L_E_T_ = ' ' "

    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cTmpPla,.F.,.F.) 

    (cTmpPla)->(DbGoTop())
    
    While (cTmpPla)->(!EOF())
        
        AADD(aDados,{(cTmpPla)->CNF_COMPET,(cTmpPla)->CNF_VLPREV})

        (cTmpPla)->(DbSkip())

    EndDo 

    (cTmpPla)->(DbCloseArea())

Return aDados
