import Vue from 'vue';
import WebAuthnAuthenticate from './authenticate';
import WebAuthnAuthenticateVue from './components/authenticate.vue';
import WebAuthnRegister from './register';

const initLegacyWebauthnAuthenticate = () => {
  const el = document.getElementById('js-register-token-2fa');

  if (!el) {
    return;
  }

  const webauthnAuthenticate = new WebAuthnAuthenticate(
    el,
    '#js-login-token-2fa-form',
    gon.webauthn,
    document.querySelector('#js-login-2fa-device'),
    document.querySelector('.js-2fa-form'),
  );
  webauthnAuthenticate.start();
};

const initVueWebauthnAuthenticate = () => {
  const el = document.getElementById('js-authentication-webauthn');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'WebAuthnRoot',
    render(createElement) {
      return createElement(WebAuthnAuthenticateVue);
    },
  });
};

export const initWebauthnAuthenticate = () => {
  if (!gon.webauthn) {
    return;
  }

  initLegacyWebauthnAuthenticate();
  initVueWebauthnAuthenticate();
};

export const initWebauthnRegister = () => {
  const el = document.getElementById('js-register-token-2fa');

  if (!el.length) {
    return;
  }

  const webauthnRegister = new WebAuthnRegister(el, gon.webauthn);
  webauthnRegister.start();
};
