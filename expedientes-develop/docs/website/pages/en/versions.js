/**
 * Copyright (c) 2017-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

const React = require('react');

const CompLibrary = require('../../core/CompLibrary');

const Container = CompLibrary.Container;

const CWD = process.cwd();

const versions = require(`${CWD}/versions.json`);

function Versions(props) {
  const {config: siteConfig} = props;
  const latestVersion = versions[0];
  //const repoUrl = `https://github.com/${siteConfig.organizationName}/${siteConfig.projectName}`;
  const repoUrl = `https://hub.siu.edu.ar/siu/expedientes`;
  return (
    <div className="docMainWrapper wrapper">
      <Container className="mainContainer versionsContainer">
        <div className="post">
          <header className="postHeader">
            <h1>Versiones de {siteConfig.title}</h1>
          </header>
          <h3 id="latest">Versión actual (Stable)</h3>
           <ul> 
              <li>
                <a
                    href={`${siteConfig.baseUrl}${siteConfig.docsUrl}/${
                      props.language ? props.language + '/' : ''
                    }arquitectura`}>
                {latestVersion}</a>: Ver <a
                    href={`${siteConfig.baseUrl}${siteConfig.docsUrl}/${
                      props.language ? props.language + '/' : ''
                    }changelog`}>
                    Changelog
                    </a>
              </li>
           </ul>
          <h3 id="rc">Próxima versión</h3>
           <ul> 
              <li>
                <a
                    href={`${siteConfig.baseUrl}${siteConfig.docsUrl}/${
                      props.language ? props.language + '/' : ''
                    }next/arquitectura`}>
                Branch develop</a>: <a href={repoUrl}>Ver código </a>
              </li>
           </ul>
              <h3 id="archive">Versiones anteriores</h3>
          <p>Aquí puede encontrar las versiones anteriores de la documentación.</p>
          <table className="versions">
            <tbody>
              {versions.map(
                version =>
                  version !== latestVersion && (
                    <tr key={version}>
                      <th>{version}</th>
                      <td>
                        {/* You are supposed to change this href where appropriate
                        Example: href="<baseUrl>/docs(/:language)/:version/:id" */}
                        <a
                          href={`${siteConfig.baseUrl}${siteConfig.docsUrl}/${
                            props.language ? props.language + '/' : ''
                          }${version}/arquitectura`}>
                          Documentación
                        </a>
                      </td>
                      <td>
                        <a
                          href={`${siteConfig.baseUrl}${siteConfig.docsUrl}/${
                            props.language ? props.language + '/' : ''
                          }${version}/changelog`}>
                          Changelog
                        </a>
                      </td>
                    </tr>
                  ),
              )}
            </tbody>
          </table>

        </div>
      </Container>
    </div>
  );
}

module.exports = Versions;
