import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import './ResetPassword.css'; // Import CSS for ResetPassword

function ResetPassword() {
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [passwordValid, setPasswordValid] = useState({
        length: false,
        lowercase: false,
        uppercase: false,
        number: false,
        symbol: false,
        match: false
    });
    const [message, setMessage] = useState('');
    const navigate = useNavigate();
    const { token } = useParams(); // Assuming the token is passed as a URL parameter
    var bp = require('./Path.js');

    useEffect(() => {
        // Password validation check on every change in newPassword or confirmPassword
        validatePassword();
    }, [newPassword, confirmPassword]);

    const validatePassword = () => {
        const isValidLength = newPassword.length >= 8 && newPassword.length <= 20;
        const hasLowercase = /[a-z]/.test(newPassword);
        const hasUppercase = /[A-Z]/.test(newPassword);
        const hasNumber = /[0-9]/.test(newPassword);
        const hasSymbol = /[!@#$%^&*()_+{}\[\]:;<>,.?~\\|-]/.test(newPassword);
        const doPasswordsMatch = newPassword === confirmPassword;

        setPasswordValid({
            length: isValidLength,
            lowercase: hasLowercase,
            uppercase: hasUppercase,
            number: hasNumber,
            symbol: hasSymbol,
            match: doPasswordsMatch
        });
    };

    const handleResetPassword = async (event) => {
        event.preventDefault();

        // Check if all password requirements are met
        if (!passwordValid.length || !passwordValid.lowercase || !passwordValid.uppercase || !passwordValid.number || !passwordValid.symbol || !passwordValid.match) {
            setMessage('Password requirements not met');
            return;
        }

        // Proceed with resetting password
        const response = await fetch(bp.buildPath('api/reset-password'), {
            method: 'POST',
            body: JSON.stringify({ token, newPassword }),
            headers: { 'Content-Type': 'application/json' }
        });

        const result = await response.json();
        if (result.success) {
            alert('Password reset successful');
            navigate('/login');
        } else {
            setMessage(result.error);
        }
    };

    return (
        <div className="reset-password-container">
            <h1>Reset Password</h1>
            <p>Enter a new password for your account</p>
            <form onSubmit={handleResetPassword}>
                <input
                    type="password"
                    placeholder="New Password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    required
                />
                <input
                    type="password"
                    placeholder="Confirm Password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    required
                />
                <div className="password-requirements">
                    <ul>
                        <li className={passwordValid.length ? 'valid' : 'invalid'}>Password length: 8-20 characters</li>
                        <li className={passwordValid.lowercase ? 'valid' : 'invalid'}>At least one lowercase letter</li>
                        <li className={passwordValid.uppercase ? 'valid' : 'invalid'}>At least one uppercase letter</li>
                        <li className={passwordValid.number ? 'valid' : 'invalid'}>At least one number</li>
                        <li className={passwordValid.symbol ? 'valid' : 'invalid'}>At least one symbol</li>
                        <li className={passwordValid.match ? 'valid' : 'invalid'}>Passwords match</li>
                    </ul>
                </div>
                <input type="submit" value="Reset Password" />
            </form>
            <span className="message">{message}</span>
        </div>
    );
}

export default ResetPassword;
