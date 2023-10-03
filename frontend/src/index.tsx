import React from 'react';
import { createRoot } from 'react-dom/client';
import './theming';
import App from './App';
import AuthContextProvider from './contexts/AuthContext';
import ApolloClientSetup from './graphql-components/apolloClientSetup/ApolloClientSetup';
import TenantContextProvider from './contexts/TenantContext';
import ErrorContextProvider from './errorHandling/ErrorContext';

const domNode = document.getElementById('root');
const root = createRoot(domNode!);

root.render(
  <React.StrictMode>
    <ErrorContextProvider>
      <AuthContextProvider>
        <ApolloClientSetup>
          <TenantContextProvider>
            <App />
          </TenantContextProvider>
        </ApolloClientSetup>
      </AuthContextProvider>
    </ErrorContextProvider>
  </React.StrictMode>
);
// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
// reportWebVitals();
