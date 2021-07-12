## Instalação com Docker-Compose

Este repositório contém os artefatos necessários para executar o X-Jus utilizando o Docker.
Antes de mais nada, será necessário instalar alguns pré-requisitos, se ainda não estiverem instalados:

- Instale o [Git](https://gist.github.com/derhuerst/1b15ff4652a867391f03)
- Instale o [Docker](https://docs.docker.com/install/)

Faça o checkout deste repositório em um diretório qualquer:

```
$ cd /var/lib
$ git clone https://github.com/x-jus/x-jus-docker.git x-jus-docker
$ cd x-jus-docker
```

Utilize o Docker para carregar e depois disponibilizar todos os serviços necessários ao funcionamento do X-Jus:

```
$ docker-compose up
```

Pronto, o X-Jus estará ativo. Para acessá-lo, aponte o navegador Google Chrome para http://localhost:8080/x-jus/api/v1/index/test/query?filter=um&page=1&perpage=5

Em alguns sistemas Linux, observamos que o ```firewalld``` impediu a comunicação entre os containers e notamos mensagens do tipo "Host unreachable" ou "Connection closed". Isso pode ser resolvido com ```sudo systemctl stop firewalld``` e depois ```sudo systemctl disable firewalld```. Também convém remover regras de filtro de pacotes com o commando ```iptables -F```. Por fim, para evitar que o espaço de IPs usado pelo Docker se sobreponha a algum outro pré-existente ajuste o arquivo conforme abaixo:

```SHELL
cat /etc/docker/daemon.json
{
   "bip": "192.168.200.3/24"
}
```

## Customizando

O funcionamento do X-Jus pode ser customizado 
para as necessidades específicas de cada empresa através de parâmetros de ambiente.
Estes parâmetros estão definidos dentro do arquivo docker-compose.yml. 

```
PROP_X-JUS_ELASTICSEARCH_URL: 'http://elastic.server:9200'
PROP_X-JUS_INDEXES: 'test'
PROP_X-JUS_INDEX_TEST_API: 'http://xjus.server:8080/x-jus/mock/record/api/v1'
PROP_X-JUS_INDEX_TEST_TOKEN: ''
PROP_X-JUS_INDEX_TEST_SECRET: '***REPLACE-WITH-RANDOM-GUID***'
PROP_X-JUS_INDEX_TEST_QUERY_JSON: '{&quot;aggregations&quot;:{&quot;tipo&quot;:{&quot;meta&quot;:{&quot;title&quot;:&quot;Tipo&quot;,&quot;field&quot;:&quot;facet_Tipo&quot;},&quot;terms&quot;:{&quot;field&quot;:&quot;facet_Tipo&quot;}},&quot;autor&quot;:{&quot;meta&quot;:{&quot;title&quot;:&quot;Autor&quot;,&quot;field&quot;:&quot;facet_Autor&quot;},&quot;terms&quot;:{&quot;field&quot;:&quot;facet_Autor&quot;}}}}'
```

A seguir, descreveremos os parâmetros que podem ser customizados e suas funções.

#### PROP_X-JUS_ELASTICSEARCH_URL

O X-Jus precisa se conectar ao ElasticSearch v7.9 para funcionar. Na presente distribuição, o próprio docker-compose já está
instanciando um ElasticSearch mas, caso prefira utilizar outro, basta indicar a URL na propriedade PROP_X-JUS_ELASTICSEARCH_URL.

```
PROP_X-JUS_ELASTICSEARCH_URL: 'http://elasticsearch.minhaempresa.com.br:9200'
```

#### PROP_X-JUS_STATUS_DIR

O X-Jus armazena em arquivos do filesystem informações a respeito do progresso de indexação de cada um dos índices por ele mantidos.
Por padrão, esses arquivos ficam no diretório ```/var/tmp``` mas, caso deseje alterarar, basta acrescentar o parâmetro, conforme exemplo abaixo:

```
PROP_X-JUS_STATUS_DIR: '/var/lib/x-jus'
```

#### PROP_X-JUS_INDEXES

Este parâmetro define quais são os índices que o X-Jus criará e manterá atualizados. 
No exemplo acima, ele está criando apenas o "test", um índice de demonstraçã que deve ser removido em uma instalação verdadeira. 
Caso quiséssemos indexar também outro sistema, o parâmetro deveria ficar assim:

```
PROP_X-JUS_INDEXES: 'test,nomedoindice'
```

Para cada índice que é criado, devem existir 4 outros parâmetros de configuração, que serão descritos a seguir. Os nomes dos parâmetros
receberão o nome do índice na sua composição. Por exemplo, para o índice "nomedoindice", o nome do primeiro parâmetro seria PROP_X-JUS_INDEX_SIGA_API.

#### PROP_X-JUS_INDEX_NOMEDOINDICE_API

Este parâmetro indica a URL da API do sistema que fornecerá os dados. Esta URL deve apontar para uma API REST dentro do padrão x-jus-record-api,
que pode ser visto neste swagger.yaml [aqui](https://github.com/x-jus/x-jus-record-api/blob/master/src/main/resources/br/jus/trf2/xjus/record/api/swagger.yaml).

```
PROP_X-JUS_INDEX_NOMEDOINDICE_API: 'https://minhaempresa.com.br/minha-fonte-de-dados/api/v1'
```

#### PROP_X-JUS_INDEX_NOMEDOINDICE_TOKEN

Para proteger a API do sistema que fornecerá os dados para o X-Jus, é conveniente que apenas o X-Jus possa acessá-la. Proteja ela com uma
senha longa que deve estar presente no cabeçalho das solicitações HTTPS, no campo "Authorization". Depois, informe a senha na propriedade
PROP_X-JUS_INDEX_NOMEDOINDICE_TOKEN para que o X-Jus inclua o ela em todas as chamadas. Lembre-se de só aceitar conexões HTTPS na API do sistema,
pois dessa forma o cabeçalho "Authorization" estará protegido.

```
PROP_X-JUS_INDEX_NOMEDOINDICE_TOKEN: 'segredo-que-proteje-a-fonte-dos-dados'
```

#### PROP_X-JUS_INDEX_NOMEDOINDICE_SECRET

Caso deseje realizar uma busca textual no X-Jus, chame o método GET /index/nomedoindice/query?filter=pesquisa&page=0&perpage=10. Este método
retornará somente os registros que estão marcados como "PUBLIC". 

Para obter também documentos sigilosos, será necessário informar um segredo no header "Authorization" da chamada ao método query acima. Este
segredo, que protege as consultas, deve ser informado no parâmetro PROP_X-JUS_INDEX_NOMEDOINDICE_SECRET.

```
PROP_X-JUS_INDEX_NOMEDOINDICE_SECRET: 'segredo-que-proteje-as-consultas'
```

- o token que será enviado no header "Authorization" para a API do sistema que fornecerá os dados;
- o segredo que deve ser enviado à API de consulta do X-Jus no header "Authorization";
- informações sobre as facetas que devem ser utilizadas no índice.

#### PROP_X-JUS_INDEX_NOMEDOINDICE_QUERY_JSON

O último parâmetro diz respeito as facetas que serão utilizadas nas consultas ao índice em questão. As facetas são produzidas de acordo com
o padrão do ElasticSearch e devem ser especificadas na forma de um JSON. No exemplo do índice "test", elas foram configuradas assim:

```JSON
{
  "aggregations": {
    "tipo": {
      "meta": {
        "title": "Tipo",
        "field": "facet_Tipo"
      },
      "terms": {
        "field": "facet_Tipo"
      }
    },
    "autor": {
      "meta": {
        "title": "Autor",
        "field": "facet_Autor"
      },
      "terms": {
        "field": "facet_Autor"
      }
    }
  }
}
```

É importante que para cada faceta exista um registro "meta" especificando o título e o nome do campo.

Para converter o JSON em uma única linha e fornecê-lo como parâmetro e preciso [minificá-lo](https://codebeautify.org/jsonminifier).

## Exemplo: Siga-Doc

Por exemplo, para configurar o X-Jus para indexar documentos do [Siga-Doc](https://github.com/projeto-siga/siga), utilize as seguintes propriedades:

```
PROP_X-JUS_INDEXES: 'siga'
PROP_X-JUS_INDEX_SIGA_API: 'http://localhost:8080/sigaex/apis/x-jus/v1'
PROP_X-JUS_INDEX_SIGA_TOKEN: '***REPLACE-WITH-RANDOM-GUID***'
PROP_X-JUS_INDEX_SIGA_SECRET: '***REPLACE-WITH-RANDOM-GUID***'
PROP_X-JUS_INDEX_SIGA_QUERY_JSON: '{&quot;aggregations&quot;:{&quot;orgao&quot;:{&quot;meta&quot;:{&quot;title&quot;:&quot;Órgão&quot;,&quot;field&quot;:&quot;facet_orgao&quot;},&quot;terms&quot;:{&quot;field&quot;:&quot;facet_orgao&quot;}},&quot;origem&quot;:{&quot;meta&quot;:{&quot;title&quot;:&quot;Origem&quot;,&quot;field&quot;:&quot;facet_origem&quot;},&quot;terms&quot;:{&quot;field&quot;:&quot;facet_origem&quot;}},&quot;especie&quot;:{&quot;meta&quot;:{&quot;title&quot;:&quot;Espécie&quot;,&quot;field&quot;:&quot;facet_especie&quot;},&quot;terms&quot;:{&quot;field&quot;:&quot;facet_especie&quot;}},&quot;modelo&quot;:{&quot;meta&quot;:{&quot;title&quot;:&quot;Modelo&quot;,&quot;field&quot;:&quot;facet_modelo&quot;},&quot;terms&quot;:{&quot;field&quot;:&quot;facet_modelo&quot;}},&quot;subscritor_lotacao&quot;:{&quot;meta&quot;:{&quot;title&quot;:&quot;Lotação do Subscritor&quot;,&quot;field&quot;:&quot;facet_subscritor_lotacao&quot;},&quot;terms&quot;:{&quot;field&quot;:&quot;facet_subscritor_lotacao&quot;}}}}' 
```

## Recompilando a Imagem e Atualizando a Versão

Caso precise realizar alterações no `standalone.xml`, será necessário recompilar a imagem para que elas sejam percebidas.
Para interromper a execução utilize `Ctrl+C`, depois execute os comandos abaixo. O parâmetro ```--no-cache```obriga o
docker-compose a baixar novamente as dependências, o que será útil quando desejar atualizar para a versão mais recente.

```
$ docker-compose build --no-cache
$ docker-compose up
```

## Executando o Siga numa Instalação Própria do JBoss

A configuração oferecida neste repositório funciona perfeitamente e pode ser utilizada em ambiente de produção por empresas
que tem um número relativamente pequeno de funcionários. Caso haja necessidade de maior capacidade computacional, será
necessário substituir essa única instância de servidor de aplicação por um cluster. Nesse caso, não é recomendado utilizar
a implantação em modo `standalone`. Para montar um servidor JBoss do zero, siga o passo a passo descrito no arquivo
`x-jus-docker/Dockerfile`.
