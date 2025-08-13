import React, { useState, useEffect } from 'react';
import { Navigate } from 'react-router-dom';
import {
  Box,
  Paper,
  TextField,
  Button,
  Typography,
  Alert,
  CircularProgress,
  Container,
  Stepper,
  Step,
  StepLabel,
  Chip,
  LinearProgress
} from '@mui/material';
import {
  Email as EmailIcon,
  Security as SecurityIcon,
  Timer as TimerIcon
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import axios from 'axios';

const EmailLoginPage = () => {
  const { isAuthenticated, loading } = useAuth();
  const [step, setStep] = useState(0); // 0: email, 1: verification code
  const [email] = useState('expotobsrl@gmail.com'); // Fixed admin email
  const [code, setCode] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [codeExpiry, setCodeExpiry] = useState(null);
  const [timeLeft, setTimeLeft] = useState(0);

  // Countdown timer for code expiration
  useEffect(() => {
    if (!codeExpiry) return;

    const timer = setInterval(() => {
      const now = new Date().getTime();
      const expiry = new Date(codeExpiry).getTime();
      const difference = expiry - now;

      if (difference > 0) {
        setTimeLeft(Math.floor(difference / 1000));
      } else {
        setTimeLeft(0);
        setStep(0); // Reset to email step if code expired
        setError('Verification code has expired. Please request a new one.');
      }
    }, 1000);

    return () => clearInterval(timer);
  }, [codeExpiry]);

  // Redirect if already authenticated
  if (isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  const formatTime = (seconds) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  const handleSendCode = async () => {
    setIsLoading(true);
    setError('');

    try {
      const response = await axios.post(`${process.env.REACT_APP_AUTH_SERVICE_URL}/send-verification`, {
        email: email
      });

      setCodeExpiry(response.data.expires_at);
      setStep(1);
      setCode('');
    } catch (error) {
      setError(error.response?.data?.message || 'Failed to send verification code');
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerifyCode = async () => {
    setIsLoading(true);
    setError('');

    try {
      const response = await axios.post(`${process.env.REACT_APP_AUTH_SERVICE_URL}/verify-code`, {
        email: email,
        code: code
      });

      // Store token and user data
      const tokenData = {
        token: response.data.token,
        expiresAt: response.data.expires_at
      };
      
      localStorage.setItem('admin_token', JSON.stringify(tokenData));
      localStorage.setItem('admin_user', JSON.stringify(response.data.user));
      
      // Set default authorization header
      axios.defaults.headers.common['Authorization'] = `Bearer ${response.data.token}`;
      
      // Redirect to dashboard
      window.location.href = '#/';
      window.location.reload();
    } catch (error) {
      setError(error.response?.data?.message || 'Invalid verification code');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCodeChange = (e) => {
    const value = e.target.value.replace(/\D/g, '').slice(0, 6);
    setCode(value);
    if (error) setError('');
  };

  const handleBackToEmail = () => {
    setStep(0);
    setCode('');
    setError('');
    setCodeExpiry(null);
  };

  if (loading) {
    return (
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100vh'
        }}
      >
        <CircularProgress />
      </Box>
    );
  }

  const steps = ['Email Verification', 'Enter Code'];

  return (
    <Container maxWidth="sm">
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100vh',
          py: 4
        }}
      >
        <Paper
          elevation={3}
          sx={{
            p: 4,
            width: '100%',
            maxWidth: 500
          }}
        >
          {/* Logo/Brand */}
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <Typography
              variant="h4"
              sx={{
                fontWeight: 700,
                color: 'primary.main',
                mb: 1
              }}
            >
              Made in World
            </Typography>
            <Typography
              variant="h6"
              color="text.secondary"
              sx={{ fontWeight: 500 }}
            >
              Admin Panel
            </Typography>
          </Box>

          {/* Stepper */}
          <Stepper activeStep={step} sx={{ mb: 4 }}>
            {steps.map((label) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>

          {/* Error Alert */}
          {error && (
            <Alert severity="error" sx={{ mb: 3 }}>
              {error}
            </Alert>
          )}

          {/* Step 0: Email Verification */}
          {step === 0 && (
            <>
              <Alert severity="info" sx={{ mb: 3 }}>
                <Typography variant="body2">
                  <strong>Email-Based Authentication:</strong> Enter your admin email to receive a 6-digit verification code.
                </Typography>
              </Alert>

              <TextField
                fullWidth
                label="Admin Email"
                value={email}
                disabled
                margin="normal"
                InputProps={{
                  startAdornment: <EmailIcon sx={{ mr: 1, color: 'text.secondary' }} />
                }}
                helperText="This is the authorized admin email address"
              />

              <Button
                fullWidth
                variant="contained"
                size="large"
                onClick={handleSendCode}
                disabled={isLoading}
                sx={{
                  mt: 3,
                  mb: 2,
                  py: 1.5,
                  fontWeight: 600
                }}
              >
                {isLoading ? (
                  <>
                    <CircularProgress size={20} sx={{ mr: 1 }} />
                    Sending Code...
                  </>
                ) : (
                  <>
                    <SecurityIcon sx={{ mr: 1 }} />
                    Send Verification Code
                  </>
                )}
              </Button>
            </>
          )}

          {/* Step 1: Code Verification */}
          {step === 1 && (
            <>
              <Alert severity="success" sx={{ mb: 3 }}>
                <Typography variant="body2">
                  <strong>Code Sent!</strong> Check your email at <strong>{email}</strong> for the 6-digit verification code.
                </Typography>
              </Alert>

              {/* Timer Display */}
              {timeLeft > 0 && (
                <Box sx={{ mb: 3 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                    <TimerIcon sx={{ mr: 1, color: 'warning.main' }} />
                    <Typography variant="body2" color="warning.main">
                      Code expires in: <strong>{formatTime(timeLeft)}</strong>
                    </Typography>
                  </Box>
                  <LinearProgress 
                    variant="determinate" 
                    value={(timeLeft / 600) * 100} 
                    sx={{ height: 6, borderRadius: 3 }}
                  />
                </Box>
              )}

              <TextField
                fullWidth
                label="Verification Code"
                value={code}
                onChange={handleCodeChange}
                margin="normal"
                placeholder="Enter 6-digit code"
                inputProps={{
                  maxLength: 6,
                  style: { 
                    textAlign: 'center', 
                    fontSize: '24px', 
                    letterSpacing: '8px',
                    fontFamily: 'monospace'
                  }
                }}
                disabled={isLoading}
                autoFocus
              />

              <Box sx={{ display: 'flex', gap: 2, mt: 3 }}>
                <Button
                  variant="outlined"
                  onClick={handleBackToEmail}
                  disabled={isLoading}
                  sx={{ flex: 1 }}
                >
                  Back
                </Button>
                
                <Button
                  variant="contained"
                  onClick={handleVerifyCode}
                  disabled={isLoading || code.length !== 6}
                  sx={{ flex: 2, fontWeight: 600 }}
                >
                  {isLoading ? (
                    <>
                      <CircularProgress size={20} sx={{ mr: 1 }} />
                      Verifying...
                    </>
                  ) : (
                    'Verify & Sign In'
                  )}
                </Button>
              </Box>

              {/* Security Info */}
              <Box sx={{ mt: 3, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
                <Typography variant="caption" color="text.secondary">
                  <strong>Security Features:</strong><br/>
                  • Code expires in 10 minutes<br/>
                  • Maximum 3 verification attempts<br/>
                  • Rate limited to 5 requests per hour
                </Typography>
              </Box>
            </>
          )}

          {/* Footer */}
          <Box sx={{ textAlign: 'center', mt: 4 }}>
            <Typography variant="body2" color="text.secondary">
              Made in World Admin Panel v2.0 - Email Authentication
            </Typography>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
};

export default EmailLoginPage;
